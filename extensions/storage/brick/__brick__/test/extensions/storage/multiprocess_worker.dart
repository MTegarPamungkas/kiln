import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:{{app_name}}/extensions/storage/storage_migrator.dart';

import 'multiprocess_support.dart';

/// Second real process for the storage migration recovery tests.
Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    stderr.writeln('usage: multiprocess_worker.dart <mode> <path...>');
    exit(64);
  }
  switch (arguments.first) {
    case 'migrate-crash':
      await _migrateAndCrash(arguments);
    case 'migrate-recover':
      await _recoverAndFinish(arguments);
    default:
      stderr.writeln('unknown mode ${arguments.first}');
      exit(64);
  }
}

/// Starts a migration step, writes part of it, then hangs until the test process
/// kills this process. The migrator's checkpoint is already on disk.
Future<void> _migrateAndCrash(List<String> arguments) async {
  final storagePath = arguments[1];
  final migrator = StorageMigrator(
    storage: JsonFileStorage(storagePath),
    targetVersion: 1,
    migrations: <StorageMigration>[
      (storage) async {
        await storage.write('half', 'applied');
        stdout.writeln('half-applied');
        await stdout.flush();
        await Completer<void>().future;
      },
    ],
  );
  await migrator.run();
}

/// A fresh process that must roll back the interrupted step and then run it.
Future<void> _recoverAndFinish(List<String> arguments) async {
  final storagePath = arguments[1];
  final storage = JsonFileStorage(storagePath);
  final migrator = StorageMigrator(
    storage: storage,
    targetVersion: 1,
    migrations: <StorageMigration>[
      (storage) async {
        await storage.write('existing', 'new');
        await storage.write('migrated', 'yes');
      },
    ],
  );
  final version = await migrator.run();
  final values = <String, Object?>{
    for (final key in (await storage.keys()).toList()..sort())
      key: await storage.read(key),
  };
  stdout.writeln('version $version');
  stdout.writeln('keys ${jsonEncode(values)}');
  await stdout.flush();
}
