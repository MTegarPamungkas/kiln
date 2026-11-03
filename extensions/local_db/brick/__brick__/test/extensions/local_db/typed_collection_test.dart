import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/local_db/typed_collection.dart';

import 'test_support.dart';

final class _Task {
  const _Task(this.title, this.done);

  final String title;
  final bool done;
}

void main() {
  test('converts documents to typed values', () async {
    final database = await openTestDatabase();
    final tasks = TypedCollection<_Task>(
      database: database,
      collection: 'tasks',
      fromJson: (data) => _Task('${data['title']}', data['done'] == true),
      toJson: (task) => {'title': task.title, 'done': task.done},
    );

    await tasks.put('1', const _Task('one', false));
    await tasks.put('2', const _Task('two', true));

    expect((await tasks.get('1'))?.title, 'one');
    final done = await tasks.query(
      query: const LocalQuery(where: {'done': true}),
    );
    expect(done.single.title, 'two');

    final streamed = await tasks.watch().first.timeout(
      const Duration(seconds: 2),
    );
    expect(streamed, hasLength(2));

    await tasks.delete('1');
    expect(await tasks.get('1'), isNull);
    await database.close();
  });
}
