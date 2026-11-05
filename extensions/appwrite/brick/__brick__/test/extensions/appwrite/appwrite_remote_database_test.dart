import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_support.dart';

void main() {
  test('create, read, update, and delete round-trip', () async {
    final fixture = createFakeRemoteDatabase();
    final database = fixture.database;

    final created = await database.create('users', {'name': 'Tegar'});
    final id = '${created['id']}';

    expect(await database.read('users', id), containsPair('name', 'Tegar'));

    final updated = await database.update('users', id, {'name': 'Tegar P'});
    expect(updated['name'], 'Tegar P');

    await database.delete('users', id);
    expect(await database.read('users', id), isNull);
  });

  test('query filters, orders, limits, and offsets', () async {
    final database = createFakeRemoteDatabase().database;
    await database.create('tasks', {'title': 'one', 'done': false});
    await database.create('tasks', {'title': 'two', 'done': true});
    await database.create('tasks', {'title': 'three', 'done': true});

    final done = await database.query(
      'tasks',
      query: const RemoteQuery(
        filters: <RemoteFilter>[
          RemoteFilter('done', RemoteFilterOperator.equals, true),
        ],
        orderBy: <RemoteOrder>[RemoteOrder('title')],
        limit: 2,
      ),
    );
    final secondPage = await database.query(
      'tasks',
      query: const RemoteQuery(
        orderBy: <RemoteOrder>[
          RemoteOrder('title', direction: RemoteSortDirection.descending),
        ],
        limit: 1,
        offset: 1,
      ),
    );

    expect(done.map((document) => document['title']), <String>['three', 'two']);
    expect(secondPage.single['title'], 'three');
  });

  test('a missing document cannot be updated or deleted', () async {
    final database = createFakeRemoteDatabase().database;

    await expectLater(
      database.update('users', 'missing', {'name': 'Nobody'}),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.remoteDatabaseNotFound,
        ),
      ),
    );
    await expectLater(
      database.delete('users', 'missing'),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.remoteDatabaseNotFound,
        ),
      ),
    );
  });

  test('watch emits the current document and later changes', () async {
    final database = createFakeRemoteDatabase().database;
    final created = await database.create('users', {'name': 'First'});
    final id = '${created['id']}';
    final received = <Map<String, Object?>?>[];
    final subscription = database.watch('users', id).listen(received.add);

    await pumpEventQueue();
    expect(received.first?['name'], 'First');

    await database.update('users', id, {'name': 'Second'});
    await pumpEventQueue();
    expect(received.last?['name'], 'Second');

    await database.delete('users', id);
    await pumpEventQueue();
    expect(received.last, isNull);

    await subscription.cancel();
  });

  test('invalid queries fail before reaching Appwrite', () async {
    final fixture = createFakeRemoteDatabase();

    await expectLater(
      fixture.database.query(
        'tasks',
        query: const RemoteQuery(
          filters: <RemoteFilter>[
            RemoteFilter('tags', RemoteFilterOperator.inList, 'not-a-list'),
          ],
        ),
      ),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    expect(fixture.gateway.calls, isEmpty);
  });
}
