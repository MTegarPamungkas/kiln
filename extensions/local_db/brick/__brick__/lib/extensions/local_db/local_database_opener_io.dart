import 'dart:io';

import 'package:kiln_core/kiln_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

import 'file_mutation_lock.dart';
import 'local_db_config.dart';

/// Absolute database file path for [config] on IO platforms.
Future<String?> localDatabasePath(LocalDbConfig config) async {
  return config.path ??
      p.join(
        (await getApplicationDocumentsDirectory()).path,
        config.databaseName,
      );
}

/// Cross-process lock for mutations that must not overlap on this database.
///
/// Pass it to `SyncQueue.flush` / `BackupExport.import` when the app can run
/// more than one isolate, engine or process (background isolate, second window,
/// desktop multi-instance).
Future<MutationLock?> localDatabaseMutationLock(LocalDbConfig config) async {
  final path = await localDatabasePath(config);
  if (path == null) {
    return null;
  }
  return FileMutationLock('$path.lock');
}

Future<Database> openLocalDatabase(
  LocalDbConfig config, {
  SembastCodec? codec,
}) async {
  final path = (await localDatabasePath(config))!;
  await Directory(p.dirname(path)).create(recursive: true);
  return databaseFactoryIo.openDatabase(path, codec: codec);
}
