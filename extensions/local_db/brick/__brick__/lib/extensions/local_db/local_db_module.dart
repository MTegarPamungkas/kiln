import 'package:kiln_core/kiln_core.dart';

import 'database_encryption.dart';
import 'local_database_opener.dart';
import 'local_db_config.dart';
import 'sembast_local_database.dart';

/// Registers the Sembast LocalDatabase with lazy opening.
final class LocalDbModule extends KilnModule {
  const LocalDbModule();

  @override
  String get id => 'local_db';

  @override
  Set<String> get provides => const <String>{'local_db'};

  @override
  void register(Registry registry) {
    const config = LocalDbConfig.defaults;
    const encryption = DatabaseEncryption();
    registry
      ..registerSingleton<LocalDbConfig>(config)
      ..registerSingleton<LocalDatabase>(
        SembastLocalDatabase(
          opener: () async {
            final secureStorage = registry.readOrNull<SecureStorage>();
            final codec = await encryption.codec(
              secureStorage: secureStorage,
              databaseName: config.databaseName,
            );
            return openLocalDatabase(config, codec: codec);
          },
        ),
      );
  }
}
