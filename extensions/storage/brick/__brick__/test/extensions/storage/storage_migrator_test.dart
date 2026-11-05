import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/storage/storage_migrator.dart';

import 'test_support.dart';

void main() {
  test('runs pending migrations and stores the target version', () async {
    final storage = createTestStorage();
    final calls = <int>[];

    final migrator = StorageMigrator(
      storage: storage,
      targetVersion: 3,
      migrations: <StorageMigration>[
        (storage) async {
          calls.add(1);
          await storage.write('step', '1');
        },
        (storage) async {
          calls.add(2);
          await storage.write('step', '2');
        },
        (storage) async {
          calls.add(3);
          await storage.write('step', '3');
        },
      ],
    );

    expect(await migrator.run(), 3);
    expect(calls, [1, 2, 3]);
    expect(await storage.read('schema_version'), '3');
    expect(await storage.read('step'), '3');

    calls.clear();
    expect(await migrator.run(), 3);
    expect(calls, isEmpty);
  });

  test('starts from a stored version', () async {
    final storage = createTestStorage();
    await storage.write('schema_version', '2');
    final calls = <int>[];

    final migrator = StorageMigrator(
      storage: storage,
      targetVersion: 3,
      migrations: <StorageMigration>[
        (storage) async => calls.add(1),
        (storage) async => calls.add(2),
        (storage) async => calls.add(3),
      ],
    );

    expect(await migrator.run(), 3);
    expect(calls, [3]);
  });
}
