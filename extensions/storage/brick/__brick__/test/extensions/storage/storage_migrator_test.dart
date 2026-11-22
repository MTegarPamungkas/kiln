import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/storage/storage_migrator.dart';

import 'test_support.dart';

void main() {
  test(
    'restores data and version if checkpoint acknowledgement fails',
    () async {
      final gateway = FakeStorageGateway()
        ..failNextWriteKey = 'app.schema_version';
      final storage = createTestStorage(gateway: gateway);
      await storage.write('existing', 'before');
      final migrator = StorageMigrator(
        storage: storage,
        targetVersion: 1,
        migrations: [
          (storage) async {
            await storage.write('existing', 'after');
            await storage.write('new', 'value');
          },
        ],
      );
      await expectLater(migrator.run(), throwsA(isA<Failure>()));
      expect(await storage.read('existing'), 'before');
      expect(await storage.read('new'), isNull);
      expect(await storage.read('schema_version'), isNull);
      expect(await migrator.run(), 1);
    },
  );

  test('serializes separate migrators sharing storage', () async {
    final storage = createTestStorage();
    var calls = 0;
    StorageMigrator create() => StorageMigrator(
      storage: storage,
      targetVersion: 1,
      migrations: [
        (storage) async {
          calls++;
          await Future<void>.delayed(Duration.zero);
          await storage.write('done', 'yes');
        },
      ],
    );
    expect(await Future.wait([create().run(), create().run()]), [1, 1]);
    expect(calls, 1);
  });

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

  test('restores a failed migration and resumes at that step', () async {
    final storage = createTestStorage();
    final calls = <int>[];
    var failOnce = true;
    final migrator = StorageMigrator(
      storage: storage,
      targetVersion: 2,
      migrations: <StorageMigration>[
        (storage) async {
          calls.add(1);
          await storage.write('step', '1');
        },
        (storage) async {
          calls.add(2);
          await storage.write('partial', 'x');
          if (failOnce) {
            failOnce = false;
            throw StateError('disk full');
          }
          await storage.write('step', '2');
        },
      ],
    );

    await expectLater(migrator.run(), throwsStateError);

    expect(await storage.read('schema_version'), '1');
    expect(await storage.read('step'), '1');
    expect(await storage.read('partial'), isNull);

    expect(await migrator.run(), 2);
    expect(calls, [1, 2, 2]);
    expect(await storage.read('step'), '2');
    expect(await storage.read('schema_version'), '2');
  });

  test('rejects a missing migration instead of advancing', () async {
    final storage = createTestStorage();
    final migrator = StorageMigrator(
      storage: storage,
      targetVersion: 2,
      migrations: <StorageMigration>[
        (storage) async => storage.write('step', '1'),
      ],
    );

    await expectLater(
      migrator.run(),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.message,
          'message',
          contains('No storage migration'),
        ),
      ),
    );
    expect(await storage.read('schema_version'), '1');
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

  test('reverts a step interrupted before its version write', () async {
    final storage = createTestStorage();
    await storage.write('existing', 'old');
    await storage.write('schema_version', '0');
    await storage.write('partial', 'half');
    await storage.write(
      '__kiln_migration_checkpoint',
      jsonEncode(<String, Object?>{
        'from': 0,
        'to': 1,
        'snapshot': <String, String>{'existing': 'old', 'schema_version': '0'},
      }),
    );
    var runs = 0;
    final migrator = StorageMigrator(
      storage: storage,
      targetVersion: 1,
      migrations: [
        (storage) async {
          runs++;
          await storage.write('existing', 'new');
        },
      ],
    );

    expect(await migrator.run(), 1);

    expect(runs, 1);
    expect(await storage.read('existing'), 'new');
    expect(await storage.read('partial'), isNull);
    expect(await storage.read('__kiln_migration_checkpoint'), isNull);
  });

  test('discards a checkpoint whose step already committed', () async {
    final storage = createTestStorage();
    await storage.write('schema_version', '1');
    await storage.write('kept', 'value');
    await storage.write(
      '__kiln_migration_checkpoint',
      jsonEncode(<String, Object?>{
        'from': 0,
        'to': 1,
        'snapshot': <String, String>{'schema_version': '0'},
      }),
    );
    final migrator = StorageMigrator(
      storage: storage,
      targetVersion: 1,
      migrations: [(_) async {}],
    );

    expect(await migrator.run(), 1);

    expect(await storage.read('kept'), 'value');
    expect(await storage.read('__kiln_migration_checkpoint'), isNull);
  });

  test('rejects an unreadable checkpoint instead of guessing', () async {
    final storage = createTestStorage();
    await storage.write('__kiln_migration_checkpoint', 'not json');
    final migrator = StorageMigrator(
      storage: storage,
      targetVersion: 1,
      migrations: [(_) async {}],
    );

    await expectLater(migrator.run(), throwsA(isA<Failure>()));
  });

  test('runs the migration while holding the supplied lock', () async {
    final storage = createTestStorage();
    final lock = _RecordingLock();
    final migrator = StorageMigrator(
      storage: storage,
      targetVersion: 1,
      lock: lock,
      migrations: [
        (storage) async {
          await storage.write('done', 'yes');
        },
      ],
    );

    expect(await migrator.run(), 1);

    expect(lock.entered, 1);
    expect(await storage.read('done'), 'yes');
  });
}

final class _RecordingLock implements MutationLock {
  int entered = 0;

  @override
  Future<T> runExclusive<T>(Future<T> Function() action) async {
    entered++;
    return action();
  }
}
