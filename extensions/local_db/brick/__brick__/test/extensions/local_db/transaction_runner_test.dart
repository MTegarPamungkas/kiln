import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';
import 'package:{{app_name}}/extensions/local_db/transaction_runner.dart';

import 'test_support.dart';

void main() {
  test('commits several writes atomically', () async {
    final database = await openTestDatabase();
    final store = stringMapStoreFactory.store('tasks');

    await const TransactionRunner().run(database, (client) async {
      await store.record('1').put(client, {'title': 'one'});
      await store.record('2').put(client, {'title': 'two'});
    });

    expect(await database.get('tasks', '1'), {'title': 'one'});
    expect(await database.get('tasks', '2'), {'title': 'two'});
    await database.close();
  });

  test('rolls back when an action throws', () async {
    final database = await openTestDatabase();
    final store = stringMapStoreFactory.store('tasks');

    await expectLater(
      const TransactionRunner().run(database, (client) async {
        await store.record('1').put(client, {'title': 'one'});
        throw StateError('rollback');
      }),
      throwsA(anything),
    );

    expect(await database.get('tasks', '1'), isNull);
    await database.close();
  });
}
