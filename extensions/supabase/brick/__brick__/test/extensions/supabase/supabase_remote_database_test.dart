import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:{{app_name}}/extensions/supabase/postgrest_gateway.dart';
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

  test('create, read, update, dan delete berjalan bolak balik', () async {
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

  test('create menolak tabel yang tidak mengembalikan id', () async {
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

  test('query memakai filter, urutan, dan limit hasil pemetaan', () async {
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

  test('update dan delete dokumen yang tidak ada menjadi notFound', () async {
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

  test('watch mengirim dokumen saat ini lalu perubahan realtime', () async {
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

  test('watch mengirim null saat dokumen dihapus', () async {
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

  test('nama tabel tidak valid ditolak sebelum request', () async {
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

  test('error PostgREST dipetakan ke Failure database', () async {
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
