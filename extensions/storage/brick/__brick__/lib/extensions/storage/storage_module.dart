import 'package:kiln_core/kiln_core.dart';

import 'shared_preferences_storage.dart';
import 'storage_config.dart';
import 'storage_gateway.dart';
import 'storage_migrator.dart';

/// Registers the SharedPreferences-backed Storage.
final class StorageModule extends KilnModule {
  const StorageModule();

  @override
  String get id => 'storage';

  @override
  Set<String> get provides => const <String>{'storage'};

  @override
  void register(Registry registry) {
    const config = StorageConfig.defaults;
    final storage = SharedPreferencesStorage(
      gateway: SharedPreferencesGateway(),
      config: config,
    );
    registry
      ..registerSingleton<StorageConfig>(config)
      ..registerSingleton<Storage>(storage)
      ..registerSingleton<StorageMigrator>(
        StorageMigrator(
          storage: storage,
          targetVersion: config.schemaVersion,
        ),
      );
  }

  @override
  Future<void> ready(Registry registry) async {
    await registry.read<StorageMigrator>().run();
  }
}
