import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

import 'first_run_wipe.dart';
import 'keystore_secure_storage.dart';
import 'secure_storage_config.dart';
import 'secure_storage_gateway.dart';

/// Registers the Keychain/Keystore SecureStorage.
final class SecureStorageModule extends KilnModule {
  const SecureStorageModule();

  @override
  String get id => 'secure_storage';

  @override
  Set<String> get provides => const <String>{'secure_storage'};

  @override
  void register(Registry registry) {
    const config = SecureStorageConfig.defaults;
    final storage = KeystoreSecureStorage(
      gateway: FlutterSecureStorageGateway(config: config),
      config: config,
    );
    registry
      ..registerSingleton<SecureStorageConfig>(config)
      ..registerSingleton<SecureStorage>(storage);
  }

  @override
  Future<void> ready(Registry registry) async {
    final markerStorage = registry.readOrNull<Storage>();
    if (markerStorage == null) {
      return;
    }
    await FirstRunWipe(
      gateway: FlutterSecureStorageGateway(),
      storage: markerStorage,
    ).run(isIOS: defaultTargetPlatform == TargetPlatform.iOS);
  }
}
