import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/local_db/backup_export.dart';
import 'package:{{app_name}}/extensions/local_db/file_mutation_lock.dart';
import 'package:{{app_name}}/extensions/local_db/sembast_local_database.dart';
import 'package:{{app_name}}/extensions/local_db/sync_queue.dart';
import 'package:sembast/sembast_io.dart';

import 'multiprocess_support.dart';

// Every test here starts at least one real second process. A process prevents
// the simulation trap the single-process suites have: POSIX locks are per
// process, so two isolates cannot prove that a cross-process lock blocks, and a
// caught exception cannot prove that a crash leaves recoverable state.
const String _workerScript =
    'test/extensions/local_db/multiprocess_worker.dart';

void main() {
  late Directory directory;
  late List<DartWorker> workers;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kiln_local_db_mp_');
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

  Future<SembastLocalDatabase> openSembast(String path) async {
    return SembastLocalDatabase(
      database: await databaseFactoryIo.openDatabase(path),
    );
  }

  test(
    'a second real process waits until the lock holder releases',
    () async {
      final lockPath = '${directory.path}/queue.lock';
      final marker = File('${directory.path}/held.marker');
      final release = File('${directory.path}/release.marker');
      final holder = await startWorker(<String>[
        'hold-lock',
        lockPath,
        marker.path,
        release.path,
      ]);
      await holder.waitForLine('locked');
      expect(await marker.exists(), isTrue);

      var entered = false;
      DateTime? enteredAt;
      final waiting = FileMutationLock(lockPath).runExclusive(() async {
        entered = true;
        enteredAt = DateTime.now();
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(
        entered,
        isFalse,
        reason: 'the other process still holds the operating-system lock',
      );

      final releasedAt = DateTime.now();
      await release.writeAsString('go', flush: true);
      await waiting.timeout(const Duration(seconds: 30));

      expect(entered, isTrue);
      expect(enteredAt!.isAfter(releasedAt), isTrue);
      expect(await holder.waitForExit(), 0);
      expect(await holder.waitForLine('released'), isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a process killed while holding the lock does not block the next writer',
    () async {
      final lockPath = '${directory.path}/crashed.lock';
      final marker = File('${directory.path}/crashed.marker');
      final holder = await startWorker(<String>[
        'crash-hold-lock',
        lockPath,
        marker.path,
      ]);
      await holder.waitForLine('locked');

      // Kill the holder without a chance to run a Dart `finally`.
      await holder.kill();
      expect(await holder.waitForExit(), isNot(0));

      final stopwatch = Stopwatch()..start();
      await FileMutationLock(lockPath)
          .runExclusive(() async {})
          .timeout(const Duration(seconds: 10));
      stopwatch.stop();

      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 5)),
        reason: 'the operating system must release a dead process\'s lock',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'racing processes deliver every queued item exactly once',
    () async {
      final databasePath = '${directory.path}/race.db.json';
      final lockPath = '${directory.path}/race.lock';
      final delivery = File('${directory.path}/delivery.log');
      final go = File('${directory.path}/go.marker');
      final database = JsonSharedDatabase(databasePath);
      final seed = SyncQueue(database: database);
      const itemCount = 24;
      for (var index = 0; index < itemCount; index++) {
        await seed.enqueue('tasks', '$index', <String, Object?>{
          'title': 'task $index',
        });
      }
      expect(await seed.pending(), hasLength(itemCount));

      final racers = <DartWorker>[];
      for (var index = 0; index < 3; index++) {
        racers.add(
          await startWorker(<String>[
            'race-flush',
            databasePath,
            lockPath,
            delivery.path,
            'worker-$index',
            go.path,
          ]),
        );
      }
      await Future.wait(<Future<String>>[
        for (final racer in racers) racer.waitForLine('ready'),
      ]);
      await go.writeAsString('go', flush: true);

      final exits = await Future.wait(<Future<int>>[
        for (final racer in racers) racer.waitForExit(),
      ]);
      expect(exits, everyElement(0));

      final lines = await delivery.readAsLines();
      final ids = <String>[];
      final intervals = <(int, int)>[];
      for (final line in lines) {
        final fields = line.split('\t');
        expect(fields, hasLength(4), reason: 'malformed delivery line: $line');
        ids.add(fields[0]);
        intervals.add((int.parse(fields[2]), int.parse(fields[3])));
      }

      // The queue lock is the only cross-process exclusion here: without it,
      // two processes can read the same pending item and both deliver it.
      expect(ids, hasLength(itemCount));
      expect(ids.toSet(), hasLength(itemCount));

      intervals.sort((left, right) => left.$1.compareTo(right.$1));
      for (var index = 1; index < intervals.length; index++) {
        expect(
          intervals[index].$1,
          greaterThanOrEqualTo(intervals[index - 1].$2),
          reason: 'two processes ran their handlers at the same time',
        );
      }

      var reported = 0;
      for (final racer in racers) {
        for (final line in racer.stdoutLines) {
          if (line.startsWith('flushed ')) {
            reported += int.parse(line.substring('flushed '.length));
          }
        }
      }
      expect(reported, itemCount);
      expect(await seed.pending(), isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'a claim left by a killed process expires and is taken over',
    () async {
      final databasePath = '${directory.path}/claims.db';
      final lockPath = '$databasePath.lock';
      final worker = await startWorker(<String>[
        'claim-and-crash',
        databasePath,
        '3',
      ]);
      await worker.waitForLine('claimed ');
      await worker.kill();

      final database = await openSembast(databasePath);
      addTearDown(database.close);

      final locked = SyncQueue(
        database: database,
        lock: FileMutationLock(lockPath),
        claimLease: const Duration(seconds: 10),
      );
      final claimedLine = await worker.waitForLine('claimed ');
      final claimedId = claimedLine.substring('claimed '.length).trim();
      final deliveredWhileClaimed = <String>[];
      final immediate = await locked
          .flush((item) async {
            deliveredWhileClaimed.add(item.id);
          })
          .timeout(const Duration(seconds: 15));
      expect(
        immediate,
        2,
        reason: 'only the two unclaimed items may be delivered',
      );
      expect(deliveredWhileClaimed, isNot(contains(claimedId)));

      final pending = await locked.pending();
      expect(pending, hasLength(1), reason: 'the live claim must be retained');
      expect(pending.single.id, claimedId);
      expect(pending.single.claimId, isNotNull);
      expect(pending.single.claimedAt, isNotNull);
      expect(pending.single.attempts, 1);

      // The lease is the recovery path when a claim outlives its owner.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final takeover = SyncQueue(
        database: database,
        lock: FileMutationLock(lockPath),
        claimLease: const Duration(milliseconds: 300),
      );
      final delivered = <String>[];
      final attempts = <String, int>{};
      final count = await takeover
          .flush((item) async {
            delivered.add(item.key);
            attempts[item.id] = item.attempts;
          })
          .timeout(const Duration(seconds: 30));

      expect(count, 1);
      expect(delivered, hasLength(1));
      expect(attempts[claimedId], 2);
      expect(await takeover.pending(), isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'an import killed mid-write is rolled back by a fresh handle',
    () async {
      final databasePath = '${directory.path}/import.db';
      final backupPath = '${directory.path}/backup.json';
      final marker = File('${directory.path}/import.marker');
      final lockPath = '$databasePath.lock';

      final seed = await openSembast(databasePath);
      await seed.put('tasks', 'keep', <String, Object?>{'title': 'keep'});
      await seed.put('tasks', 'replaced', <String, Object?>{
        'title': 'before',
      });
      await seed.close();

      final backup = <String, Object?>{
        'version': 1,
        'collections': <String, Object?>{
          'tasks': <Object?>[
            <String, Object?>{
              'key': 'new',
              'data': <String, Object?>{'title': 'new'},
            },
            <String, Object?>{
              'key': 'replaced',
              'data': <String, Object?>{'title': 'after'},
            },
          ],
        },
      };
      await File(backupPath).writeAsString(jsonEncode(backup), flush: true);

      final worker = await startWorker(<String>[
        'import-and-crash',
        databasePath,
        backupPath,
        marker.path,
        '1',
      ]);
      expect(
        await worker.waitForExit(),
        70,
        reason: 'the worker must die inside the import, not finish it',
      );
      expect(await marker.exists(), isTrue);

      final database = await openSembast(databasePath);
      addTearDown(database.close);

      // The crash happened after the first write: it is on disk, the journal is
      // still active, and the untouched record keeps its old value.
      expect((await database.get('tasks', 'new'))?['title'], 'new');
      expect((await database.get('tasks', 'replaced'))?['title'], 'before');
      final status = await database.get(
        '_kiln_import_journal',
        '__status__',
      );
      expect(status?['active'], isTrue);

      final recovered = await BackupExport()
          .recover(
            database: database,
            lock: FileMutationLock(lockPath),
          )
          .timeout(const Duration(seconds: 30));
      expect(recovered, isTrue);
      expect(await database.get('tasks', 'new'), isNull);
      expect((await database.get('tasks', 'replaced'))?['title'], 'before');
      expect((await database.get('tasks', 'keep'))?['title'], 'keep');
      expect(await database.query('_kiln_import_journal'), isEmpty);

      await BackupExport().import(
        database: database,
        backup: backup,
        lock: FileMutationLock(lockPath),
      );
      expect((await database.get('tasks', 'new'))?['title'], 'new');
      expect((await database.get('tasks', 'replaced'))?['title'], 'after');
      expect((await database.get('tasks', 'keep'))?['title'], 'keep');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
