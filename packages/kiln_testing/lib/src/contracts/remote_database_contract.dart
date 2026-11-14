import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef RemoteDatabaseContractFactory = FutureOr<RemoteDatabase> Function();

/// Behavior every [RemoteDatabase] implementation must share.
void remoteDatabaseContract({
  required RemoteDatabaseContractFactory create,
  String description = 'RemoteDatabase',
  Duration timeout = const Duration(seconds: 2),
}) {
  group('$description contract', () {
    test('create, read, update, and delete a document', () async {
      final database = await create();

      final created = await database.create('users', {'name': 'Tegar'});
      final id = created['id'];
      expect(id, isNotNull);

      final readBack = await database.read('users', '$id');
      expect(readBack?['name'], 'Tegar');

      final updated = await database.update('users', '$id', {
        'name': 'Tegar P',
      });
      expect(updated['name'], 'Tegar P');

      await database.delete('users', '$id');
      expect(await database.read('users', '$id'), isNull);
    });

    test('query applies filters, ordering, and limits', () async {
      final database = await create();
      await database.create('tasks', {'title': 'one', 'done': false});
      await database.create('tasks', {'title': 'two', 'done': true});
      await database.create('tasks', {'title': 'three', 'done': true});

      final done = await database.query(
        'tasks',
        query: const RemoteQuery(
          filters: [RemoteFilter('done', RemoteFilterOperator.equals, true)],
          orderBy: [RemoteOrder('title')],
          limit: 2,
        ),
      );

      expect(done, hasLength(2));
      expect(done.map((document) => document['title']), ['three', 'two']);
    });

    test('watch emits the current document and later updates', () async {
      final database = await create();
      final created = await database.create('users', {'name': 'First'});
      final id = '${created['id']}';

      // One subscription observes both phases: the current document first,
      // then the update. Waiting for the first emission keeps the update
      // below from racing a backend handshake that has not subscribed yet.
      final current = Completer<Map<String, Object?>?>();
      final updated = Completer<Map<String, Object?>?>();
      final subscription = database.watch('users', id).listen((document) {
        if (document?['name'] == 'Second') {
          if (!updated.isCompleted) {
            updated.complete(document);
          }
        } else if (!current.isCompleted) {
          current.complete(document);
        }
      });

      expect((await current.future.timeout(timeout))?['name'], 'First');
      await database.update('users', id, {'name': 'Second'});
      expect((await updated.future.timeout(timeout))?['name'], 'Second');
      await subscription.cancel();
    });

    test('a missing document cannot be updated or deleted', () async {
      final database = await create();

      await expectLater(
        database.update('users', 'missing', {'name': 'Nobody'}),
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
  });
}
