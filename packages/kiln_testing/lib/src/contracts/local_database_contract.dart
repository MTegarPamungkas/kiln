import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef LocalDatabaseContractFactory = FutureOr<LocalDatabase> Function();

/// Behavior every [LocalDatabase] implementation must share.
void localDatabaseContract({
  required LocalDatabaseContractFactory create,
  String description = 'LocalDatabase',
  Duration timeout = const Duration(seconds: 2),
}) {
  group('$description contract', () {
    test('put, get, overwrite, and delete round-trip', () async {
      final database = await create();

      await database.put('users', '1', {'name': 'Tegar'});
      expect(await database.get('users', '1'), {'name': 'Tegar'});

      await database.put('users', '1', {'name': 'Tegar P'});
      expect(await database.get('users', '1'), {'name': 'Tegar P'});

      await database.delete('users', '1');
      expect(await database.get('users', '1'), isNull);

      await database.close();
    });

    test('query filters, orders, and limits records', () async {
      final database = await create();
      await database.put('tasks', '1', {'title': 'one', 'done': false});
      await database.put('tasks', '2', {'title': 'two', 'done': true});
      await database.put('tasks', '3', {'title': 'three', 'done': true});

      final done = await database.query(
        'tasks',
        query: const LocalQuery(where: {'done': true}),
      );
      expect(done.map((record) => record.key), containsAll(<String>['2', '3']));
      expect(done, hasLength(2));

      final ordered = await database.query(
        'tasks',
        query: const LocalQuery(orderBy: 'title', limit: 2),
      );
      expect(ordered.map((record) => record.data['title']), ['one', 'three']);

      await database.close();
    });

    test('watch emits the current records and later changes', () async {
      final database = await create();
      await database.put('users', '1', {'name': 'First'});

      final next = database
          .watch('users')
          .firstWhere((records) => records.any((record) => record.key == '2'));
      await database.put('users', '2', {'name': 'Second'});

      final records = await next.timeout(timeout);
      expect(records, hasLength(greaterThanOrEqualTo(2)));

      await database.close();
    });
  });
}
