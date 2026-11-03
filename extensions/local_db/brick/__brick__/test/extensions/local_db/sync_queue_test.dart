import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/local_db/sync_queue.dart';

import 'test_support.dart';

void main() {
  test('stores and flushes pending changes', () async {
    final database = await openTestDatabase();
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final queue = SyncQueue(database: database, clock: clock);

    final first = await queue.enqueue('tasks', '1', {'title': 'one'});
    clock.advance(const Duration(seconds: 1));
    final second = await queue.enqueue(
      'tasks',
      '2',
      {'title': 'two'},
      operation: 'delete',
    );

    final pending = await queue.pending();
    expect(pending.map((item) => item.id), [first, second]);
    expect(pending.last.operation, 'delete');

    final flushed = <String>[];
    final count = await queue.flush((item) async {
      flushed.add(item.key);
    });

    expect(count, 2);
    expect(flushed, ['1', '2']);
    expect(await queue.pending(), isEmpty);
    await database.close();
  });
}
