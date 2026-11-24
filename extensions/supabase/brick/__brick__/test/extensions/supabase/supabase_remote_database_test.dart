import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:{{app_name}}/extensions/supabase/postgrest_gateway.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_realtime_gateway.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_remote_database.dart';

import 'test_support.dart';

void main() {
  late FakeDocumentStore store;
  late FakePostgrestGateway postgrest;
  late FakeSupabaseRealtimeGateway realtime;
  late SupabaseRemoteDatabase database;

  setUp(() {
    store = FakeDocumentStore();
    postgrest = FakePostgrestGateway(store: store);
    realtime = FakeSupabaseRealtimeGateway(store);
    database = SupabaseRemoteDatabase(postgrest: postgrest, realtime: realtime);
  });

  test('create, read, update, and delete round-trip', () async {
    final created = await database.create('users', <String, Object?>{
      'name': 'Tegar',
    });
    final id = '${created['id']}';
    expect(id, isNotEmpty);

    expect((await database.read('users', id))?['name'], 'Tegar');

    final updated = await database.update('users', id, <String, Object?>{
      'name': 'Tegar P',
    });
    expect(updated['name'], 'Tegar P');
    expect(updated['id'], id);

    await database.delete('users', id);
    expect(await database.read('users', id), isNull);
  });

  test('create rejects a table that returns no id', () async {
    final withoutId = _IdlessPostgrestGateway();

    final failing = SupabaseRemoteDatabase(
      postgrest: withoutId,
      realtime: realtime,
    );

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
        orderBy: <RemoteOrder>[RemoteOrder('title')],
        limit: 2,
      ),
    );

    expect(rows.map((row) => row['title']), <String>['three', 'two']);
    expect(
      postgrest.lastQuery?.filters.single.operator,
      PostgrestOperator.equals,
    );
    expect(postgrest.lastQuery?.orderBy.single.ascending, isTrue);
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

  test('watch emits the current document then realtime changes', () async {
    final created = await database.create('users', <String, Object?>{
      'name': 'First',
    });
    final id = '${created['id']}';
    final received = <Map<String, Object?>?>[];
    final subscription = database.watch('users', id).listen(received.add);

    await Future<void>.delayed(Duration.zero);
    await database.update('users', id, <String, Object?>{'name': 'Second'});
    await Future<void>.delayed(Duration.zero);

    expect(received.first?['name'], 'First');
    expect(received.last?['name'], 'Second');
    expect(realtime.activeSubscriptions, 1);

    await subscription.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(realtime.activeSubscriptions, 0);
  });

  test('watch emits null when the document is deleted', () async {
    final created = await database.create('users', <String, Object?>{
      'name': 'Gone',
    });
    final id = '${created['id']}';
    final rows = <Map<String, Object?>?>[];
    final subscription = database.watch('users', id).listen(rows.add);

    await Future<void>.delayed(Duration.zero);
    await database.delete('users', id);
    await Future<void>.delayed(Duration.zero);

    expect(rows.last, isNull);

    await subscription.cancel();
  });

  test('an invalid table name is rejected before the request', () async {
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
  });

  test('a PostgREST error maps to a database Failure', () async {
    postgrest.failure = const PostgrestException(
      message: 'relation "users" does not exist',
      code: '42P01',
    );

    await expectLater(
      database.read('users', 'id-1'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.remoteDatabaseQueryFailed,
        ),
      ),
    );
  });

  group('SdkSupabaseRealtimeGateway.handleSubscribeStatus', () {
    test('channelError emits a remoteDatabaseUnavailable Failure', () async {
      final controller = StreamController<Map<String, Object?>?>();
      final errors = <Object>[];
      final sub = controller.stream.listen((_) {}, onError: errors.add);

      SdkSupabaseRealtimeGateway.handleSubscribeStatus(
        status: RealtimeSubscribeStatus.channelError,
        error: StateError('socket dropped'),
        table: 'tasks',
        id: '1',
        controller: controller,
      );
      await Future<void>.delayed(Duration.zero);

      expect(errors, hasLength(1));
      final failure = errors.single as Failure;
      expect(failure.code, FailureCode.remoteDatabaseUnavailable);
      expect(failure.kind, FailureKind.network);

      await sub.cancel();
      await controller.close();
    });

    test('timedOut emits a retryable networkTimeout Failure', () async {
      final controller = StreamController<Map<String, Object?>?>();
      final errors = <Object>[];
      final sub = controller.stream.listen((_) {}, onError: errors.add);

      SdkSupabaseRealtimeGateway.handleSubscribeStatus(
        status: RealtimeSubscribeStatus.timedOut,
        error: null,
        table: 'tasks',
        id: '1',
        controller: controller,
      );
      await Future<void>.delayed(Duration.zero);

      expect(errors, hasLength(1));
      final failure = errors.single as Failure;
      expect(failure.code, FailureCode.networkTimeout);
      expect(failure.kind, FailureKind.network);
      expect(failure.isRetryable, isTrue);

      await sub.cancel();
      await controller.close();
    });

    test('closed completes the stream cleanly', () async {
      final controller = StreamController<Map<String, Object?>?>();
      var done = false;
      final sub = controller.stream.listen((_) {}, onDone: () => done = true);

      SdkSupabaseRealtimeGateway.handleSubscribeStatus(
        status: RealtimeSubscribeStatus.subscribed,
        error: null,
        table: 'tasks',
        id: '1',
        controller: controller,
      );
      expect(done, isFalse);

      SdkSupabaseRealtimeGateway.handleSubscribeStatus(
        status: RealtimeSubscribeStatus.closed,
        error: null,
        table: 'tasks',
        id: '1',
        controller: controller,
      );
      await Future<void>.delayed(Duration.zero);

      expect(done, isTrue);
      await sub.cancel();
    });
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
