import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'multiprocess_support.dart';

// The storage migration suite runs the crash in a third process: the migrator
// checkpoints the pre-step snapshot, a real process death leaves that checkpoint
// behind, and a fresh process has to restore it before retrying the step. The
// advisory lock that excludes concurrent migrators is exercised by the
// `local_db` multi-process suite, which owns the concrete lock implementation.
const String _workerScript =
    'test/extensions/storage/multiprocess_worker.dart';
const String _checkpointKey = '__kiln_migration_checkpoint';

void main() {
  late Directory directory;
  late List<DartWorker> workers;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kiln_storage_mp_');
    workers = <DartWorker>[];
  });

  tearDown(() async {
    for (final worker in workers) {
      await worker.kill();
    }
    try {
      await directory.delete(recursive: true);
    } on FileSystemException {
      // A killed process can hold a handle for a moment on Windows.
    }
  });

  Future<DartWorker> startWorker(List<String> arguments) async {
    final worker = await DartWorker.start(
      _workerScript,
      arguments,
      workingDirectory: Directory.current.path,
    );
    workers.add(worker);
    return worker;
  }

  test(
    'a migration killed inside a step is rolled back and retried by a new process',
    () async {
      final storagePath = '${directory.path}/storage.json';
      final storage = JsonFileStorage(storagePath);
      await storage.write('schema_version', '0');
      await storage.write('existing', 'old');
      await storage.write('keep', 'value');

      final crashing = await startWorker(<String>[
        'migrate-crash',
        storagePath,
      ]);
      await crashing.waitForLine('half-applied');
      await crashing.kill();
      expect(await crashing.waitForExit(), isNot(0));

      // The dead process left the half-applied key and the checkpoint that
      // records the state before the step.
      expect(await storage.read('half'), 'applied');
      expect(await storage.read('schema_version'), '0');
      final rawCheckpoint = await storage.read(_checkpointKey);
      expect(rawCheckpoint, isNotNull);
      final checkpoint = jsonDecode(rawCheckpoint!) as Map;
      expect(checkpoint['from'], 0);
      expect(checkpoint['to'], 1);
      final snapshot = checkpoint['snapshot'] as Map;
      expect(snapshot['existing'], 'old');
      expect(snapshot['schema_version'], '0');
      expect(snapshot.containsKey('half'), isFalse);

      // A fresh process must restore the snapshot, drop the partial write, and
      // then run the step again to completion.
      final recovering = await startWorker(<String>[
        'migrate-recover',
        storagePath,
      ]);
      expect(await recovering.waitForExit(), 0);
      final keysLine = await recovering.waitForLine('keys ');
      expect(await recovering.waitForLine('version '), 'version 1');

      final keys =
          jsonDecode(keysLine.substring('keys '.length)) as Map<String, Object?>;
      expect(keys['schema_version'], '1');
      expect(keys['existing'], 'new');
      expect(keys['migrated'], 'yes');
      expect(keys['keep'], 'value');
      expect(keys.containsKey('half'), isFalse);
      expect(keys.containsKey(_checkpointKey), isFalse);

      // The file itself must match what the recovering process reported.
      expect(await storage.read('schema_version'), '1');
      expect(await storage.read('existing'), 'new');
      expect(await storage.read('half'), isNull);
      expect(await storage.read(_checkpointKey), isNull);
      expect(await storage.read('keep'), 'value');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
