import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/local_db/schema_migrator.dart';

import 'test_support.dart';

void main() {
  test('runs pending migrations once and records the version', () async {
    final database = await openTestDatabase();
    final calls = <int>[];

    final migrator = SchemaMigrator(
      database: database,
      targetVersion: 2,
      migrations: <LocalDbMigration>[
        (database) async {
          calls.add(1);
          await database.put('_meta', 'migrated', {'value': 1});
        },
        (database) async {
          calls.add(2);
          await database.put('_meta', 'migrated', {'value': 2});
        },
      ],
    );

    expect(await migrator.run(), 2);
    expect(calls, [1, 2]);
    expect(await migrator.run(), 2);
    expect(calls, [1, 2]);
    await database.close();
  });
}
