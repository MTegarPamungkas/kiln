import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:{{app_name}}/extensions/local_db/backup_export.dart';
import 'package:{{app_name}}/extensions/local_db/file_mutation_lock.dart';
import 'package:{{app_name}}/extensions/local_db/sembast_local_database.dart';
import 'package:{{app_name}}/extensions/local_db/sync_queue.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:sembast/sembast_io.dart';

import 'multiprocess_support.dart';

/// Second real process for the multi-process tests.
///
/// Each mode exercises one side of a cross-process contract; the test process
/// coordinates through marker files and hard-kills the worker when the scenario
/// needs a crash that no `catch` or `finally` can handle.
Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    stderr.writeln('usage: multiprocess_worker.dart <mode> <path...>');
    exit(64);
  }
  switch (arguments.first) {
    case 'hold-lock':
      await _holdLock(arguments);
    case 'crash-hold-lock':
      await _crashHoldLock(arguments);
    case 'race-flush':
      await _raceFlush(arguments);
    case 'claim-and-crash':
      await _claimAndCrash(arguments);
    case 'import-and-crash':
      await _importAndCrash(arguments);
    default:
      stderr.writeln('unknown mode ${arguments.first}');
      exit(64);
  }
}

Future<void> _holdLock(List<String> arguments) async {
  final lockPath = arguments[1];
  final markerPath = arguments[2];
  final releasePath = arguments[3];
  final lock = FileMutationLock(lockPath);
  await lock.runExclusive(() async {
    await File(markerPath).writeAsString('locked', flush: true);
    stdout.writeln('locked');
    await stdout.flush();
    await waitForFile(releasePath);
  });
  stdout.writeln('released');
  await stdout.flush();
}

Future<void> _crashHoldLock(List<String> arguments) async {
  final lockPath = arguments[1];
  final markerPath = arguments[2];
  final lock = FileMutationLock(lockPath);
  await lock.runExclusive(() async {
    await File(markerPath).writeAsString('locked', flush: true);
    stdout.writeln('locked');
    await stdout.flush();
    // The test process kills this worker; the lock must be released by the
    // operating system, not by a Dart `finally`.
    await Completer<void>().future;
  });
}

Future<void> _raceFlush(List<String> arguments) async {
  final databasePath = arguments[1];
  final lockPath = arguments[2];
  final deliveryPath = arguments[3];
  final workerId = arguments[4];
  final goPath = arguments[5];
  final database = JsonSharedDatabase(databasePath);
  final queue = SyncQueue(
    database: database,
    lock: FileMutationLock(lockPath),
  );
  stdout.writeln('ready');
  await stdout.flush();
  await waitForFile(goPath);
  final count = await queue.flush((item) async {
    final begin = DateTime.now().microsecondsSinceEpoch;
    // Hold the item long enough that overlapping handlers would be observable.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final end = DateTime.now().microsecondsSinceEpoch;
    await File(deliveryPath).writeAsString(
      '${item.id}\t$workerId\t$begin\t$end\n',
      mode: FileMode.append,
      flush: true,
    );
  });
  stdout.writeln('flushed $count');
  await stdout.flush();
  await database.close();
}

Future<void> _claimAndCrash(List<String> arguments) async {
  final databasePath = arguments[1];
  final count = int.parse(arguments[2]);
  final database = SembastLocalDatabase(
    database: await databaseFactoryIo.openDatabase(databasePath),
  );
  final queue = SyncQueue(
    database: database,
    lock: FileMutationLock('$databasePath.lock'),
  );
  for (var index = 0; index < count; index++) {
    await queue.enqueue('tasks', '$index', <String, Object?>{
      'title': 'task $index',
    });
  }
  stdout.writeln('enqueued');
  await stdout.flush();
  await queue.flush((item) async {
    stdout.writeln('claimed ${item.id}');
    await stdout.flush();
    // The test process kills this worker while the claim is live.
    await Completer<void>().future;
  });
}

Future<void> _importAndCrash(List<String> arguments) async {
  final databasePath = arguments[1];
  final backupPath = arguments[2];
  final markerPath = arguments[3];
  final crashAfter = int.parse(arguments[4]);
  final inner = SembastLocalDatabase(
    database: await databaseFactoryIo.openDatabase(databasePath),
  );
  final database = _CrashAfterWriteDatabase(
    inner,
    crashAfter: crashAfter,
    markerPath: markerPath,
  );
  final decoded = jsonDecode(await File(backupPath).readAsString());
  await BackupExport().import(
    database: database,
    backup: Map<String, Object?>.from(decoded as Map),
    lock: FileMutationLock('$databasePath.lock'),
  );
  stdout.writeln('import-completed');
  await stdout.flush();
  await database.close();
}

/// Crashes the process once [crashAfter] records were written outside the
/// journal, leaving a live journal and a partly applied import behind.
final class _CrashAfterWriteDatabase implements LocalDatabase {
  _CrashAfterWriteDatabase(
    this._inner, {
    required this.crashAfter,
    required this.markerPath,
  });

  static const String journalCollection = '_kiln_import_journal';

  final LocalDatabase _inner;
  final int crashAfter;
  final String markerPath;
  int _written = 0;

  @override
  Future<void> put(
    String collection,
    String key,
    Map<String, Object?> data,
  ) async {
    await _inner.put(collection, key, data);
    if (collection == journalCollection) {
      return;
    }
    _written++;
    if (_written >= crashAfter) {
      await File(markerPath).writeAsString(
        'writes=$_written',
        flush: true,
      );
      stdout.writeln('crashing after $_written data writes');
      await stdout.flush();
      exit(70);
    }
  }

  @override
  Future<Map<String, Object?>?> get(String collection, String key) =>
      _inner.get(collection, key);

  @override
  Future<List<LocalRecord>> query(
    String collection, {
    LocalQuery? query,
  }) => _inner.query(collection, query: query);

  @override
  Future<void> delete(String collection, String key) =>
      _inner.delete(collection, key);

  @override
  Stream<List<LocalRecord>> watch(String collection, {LocalQuery? query}) =>
      _inner.watch(collection, query: query);

  @override
  Future<void> close() => _inner.close();
}
