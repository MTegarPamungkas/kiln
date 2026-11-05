import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_gateway.dart';
import 'package:{{app_name}}/extensions/neon/neon_remote_database.dart';

import 'test_support.dart';

void main() {
  late FakeDocumentStore store;
  late FakePostgrestGateway gateway;
  late NeonRemoteDatabase database;

  setUp(() {
    store = FakeDocumentStore();
    gateway = FakePostgrestGateway(store: store);
    database = NeonRemoteDatabase(gateway: gateway, config: testConfig());
  });

  NeonRemoteDatabase databaseWith(FakePostgrestGateway gw) {
    return NeonRemoteDatabase(gateway: gw, config: testConfig());
  }

  test('create, read, update, and delete round-trip', () async {
    final created = await database.create('users', <String, Object?>{
      'name': 'Tegar',
    });
    final id = '${created['id']}';
    expect(id, isNotEmpty);

    expect((await database.read('users', id))?['name'], 'Tegar');

    final updated = await database.update(
      'users',
      id,
      <String, Object?>{'name': 'Tegar P'},
    );
    expect(updated['name'], 'Tegar P');
    expect(updated['id'], id);

    await database.delete('users', id);
    expect(await database.read('users', id), isNull);
  });

  test('create rejects a table that returns no id', () async {
    final failing = databaseWith(_IdlessPostgrestGateway());

    await expectLater(
      failing.create('users', <String, Object?>{'name': 'Tegar'}),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.remoteDatabaseQueryFailed,
        ),
      ),
    );
  });

  test('query uses the mapped filter, order, and limit', () async {
    await database.create('tasks', <String, Object?>{
      'title': 'one',
      'done': false,
    });
    await database.create('tasks', <String, Object?>{
      'title': 'two',
      'done': true,
    });
    await database.create('tasks', <String, Object?>{
      'title': 'three',
      'done': true,
    });

    final rows = await database.query(
      'tasks',
      query: const RemoteQuery(
        filters: <RemoteFilter>[
          RemoteFilter('done', RemoteFilterOperator.equals, true),
        ],
        orderBy: <RemoteOrder>[RemoteOrder('title', direction: RemoteSortDirection.descending)],
        limit: 2,
      ),
    );

    expect(rows.map((row) => row['title']), <String>['two', 'three']);
    expect(gateway.lastQuery?.filters.single.operator, PostgrestOperator.equals);
    expect(gateway.lastQuery?.orderBy.single.ascending, isFalse);
  });

  test('updating and deleting a missing document becomes notFound', () async {
    await expectLater(
      database.update('users', 'missing', <String, Object?>{'name': 'x'}),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.remoteDatabaseNotFound,
        ),
      ),
    );
    await expectLater(
      database.delete('users', 'missing'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.remoteDatabaseNotFound,
        ),
      ),
    );
  });

  test('watch emits the current row then a polled change', () async {
    final created = await database.create('users', <String, Object?>{
      'name': 'First',
    });
    final id = '${created['id']}';
    final received = <Map<String, Object?>?>[];
    final subscription = database.watch('users', id).listen(received.add);

    await Future<void>.delayed(const Duration(milliseconds: 25));
    await database.update('users', id, <String, Object?>{'name': 'Second'});
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(received.first?['name'], 'First');
    expect(received.last?['name'], 'Second');

    await subscription.cancel();
  });

  test('watch does not re-emit an unchanged row', () async {
    final created = await database.create('users', <String, Object?>{
      'name': 'Stable',
    });
    final id = '${created['id']}';
    final received = <Map<String, Object?>?>[];
    final subscription = database.watch('users', id).listen(received.add);

    await Future<void>.delayed(const Duration(milliseconds: 60));
    await subscription.cancel();

    expect(received, hasLength(1));
    expect(received.single?['name'], 'Stable');
  });

  test('watch emits null when the row is deleted', () async {
    final created = await database.create('users', <String, Object?>{
      'name': 'Gone',
    });
    final id = '${created['id']}';
    final rows = <Map<String, Object?>?>[];
    final subscription = database.watch('users', id).listen(rows.add);

    await Future<void>.delayed(const Duration(milliseconds: 25));
    await database.delete('users', id);
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(rows.last, isNull);

    await subscription.cancel();
  });

  test('an invalid table name is rejected before the request', () async {
    final before = gateway.callCount;

    await expectLater(
      database.read('users; drop table', 'id-1'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    expect(gateway.callCount, before);
  });

  test('a gateway error maps to a database Failure', () async {
    gateway.failure = const NeonApiException(
      'relation "users" does not exist',
      statusCode: 404,
    );

    await expectLater(
      database.read('users', 'id-1'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.remoteDatabaseNotFound,
        ),
      ),
    );
  });
}

final class _IdlessPostgrestGateway extends FakePostgrestGateway {
  @override
  Future<Map<String, Object?>> insert(
    String table,
    Map<String, Object?> data,
  ) async {
    return <String, Object?>{'name': data['name']};
  }
}
