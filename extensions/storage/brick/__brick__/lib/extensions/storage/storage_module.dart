import 'package:kiln_core/kiln_core.dart';

import 'shared_preferences_storage.dart';
import 'storage_config.dart';
import 'storage_gateway.dart';
import 'storage_migrator.dart';
import 'storage_support.dart';

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
    final gateway = SharedPreferencesGateway();
    final storage = SharedPreferencesStorage(gateway: gateway, config: config);
    registry
      ..registerSingleton<StorageConfig>(config)
      ..registerSingleton<StorageSupport>(StorageSupport(gateway: gateway))
      ..registerSingleton<Storage>(storage)
      ..registerSingleton<StorageMigrator>(
        StorageMigrator(storage: storage, targetVersion: config.schemaVersion),
      );
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<StorageSupport>().check();
  }

  @override
  Future<void> ready(Registry registry) async {
    try {
      await registry.read<StorageMigrator>().run();
    } on Object catch (error) {
      registry.readOrNull<SupportRegistry>()?.record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Storage migration failed: $error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
    }
  }
}
