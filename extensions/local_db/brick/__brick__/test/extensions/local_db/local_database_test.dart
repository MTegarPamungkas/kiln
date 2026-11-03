import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';

import 'test_support.dart';

void main() {
  test('put, get, query, watch, and delete', () async {
    final database = await openTestDatabase();

    await database.put('tasks', '1', {'title': 'one', 'done': false});
    await database.put('tasks', '2', {'title': 'two', 'done': true});
    await database.put('tasks', '3', {'title': 'three', 'done': true});

    expect(await database.get('tasks', '1'), {'title': 'one', 'done': false});

    final done = await database.query(
      'tasks',
      query: const LocalQuery(where: {'done': true}),
    );
    expect(done.map((record) => record.key), containsAll(<String>['2', '3']));

    final ordered = await database.query(
      'tasks',
      query: const LocalQuery(orderBy: 'title', limit: 2),
    );
    expect(ordered.map((record) => record.data['title']), ['one', 'three']);

    final next = database
        .watch('tasks')
        .firstWhere(
          (records) => records.any((record) => record.key == '4'),
        );
    await database.put('tasks', '4', {'title': 'four', 'done': false});
    expect(await next.timeout(const Duration(seconds: 2)), hasLength(4));

    await database.delete('tasks', '1');
    expect(await database.get('tasks', '1'), isNull);
    await database.close();
  });
}
