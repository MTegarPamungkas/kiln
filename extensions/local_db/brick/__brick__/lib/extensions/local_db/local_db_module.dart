import 'package:kiln_core/kiln_core.dart';

import 'backup_export.dart';
import 'database_encryption.dart';
import 'local_database_opener.dart';
import 'local_database_support.dart';
import 'local_db_config.dart';
import 'sembast_local_database.dart';

/// Registers the Sembast LocalDatabase with lazy opening.
final class LocalDbModule extends KilnModule {
  LocalDbModule();

  SembastLocalDatabase? _database;

  @override
  String get id => 'local_db';

  @override
  Set<String> get provides => const <String>{'local_db'};

  @override
  Set<String> get optionalRequires => const <String>{'secure_storage'};

  @override
  void register(Registry registry) {
    const config = LocalDbConfig.defaults;
    const encryption = DatabaseEncryption();
    final support = LocalDatabaseSupport(config: config);
    final database = SembastLocalDatabase(
      opener: () async {
        final secureStorage = registry.readOrNull<SecureStorage>();
        final codec = await encryption.codec(
          secureStorage: secureStorage,
          databaseName: config.databaseName,
        );
        return openLocalDatabase(config, codec: codec);
      },
    );
    _database = database;
    registry
      ..registerSingleton<LocalDbConfig>(config)
      ..registerSingleton<LocalDatabaseSupport>(support)
      ..registerSingleton<LocalDatabase>(database);
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<LocalDatabaseSupport>().check();
  }

  @override
  Future<void> ready(Registry registry) async {
    final config = registry.readOrNull<LocalDbConfig>();
    if (config != null && !config.recoverIncompleteImports) {
      return;
    }
    final database = _database;
    if (database == null) {
      return;
    }
    try {
      // A previous process may have died inside a backup import; restore the
      // previous values before the application reads anything.
      await const BackupExport().recover(database: database);
    } on Object catch (error) {
      registry.readOrNull<SupportRegistry>()?.record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message:
              'An interrupted backup import could not be rolled back: '
              '$error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    final database = _database;
    _database = null;
    try {
      await database?.close();
    } on Object {
      // Shutdown must not fail because a lazy open already failed.
    }
  }
}
