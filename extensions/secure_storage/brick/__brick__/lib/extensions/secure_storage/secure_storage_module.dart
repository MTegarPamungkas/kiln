import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

import 'first_run_wipe.dart';
import 'keystore_secure_storage.dart';
import 'secure_storage_config.dart';
import 'secure_storage_gateway.dart';
import 'secure_storage_support.dart';

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
    final gateway = FlutterSecureStorageGateway(config: config);
    final storage = KeystoreSecureStorage(gateway: gateway, config: config);
    final support = SecureStorageSupport(gateway: gateway);
    registry
      ..registerSingleton<SecureStorageConfig>(config)
      ..registerSingleton<SecureStorageSupport>(support)
      ..registerSingleton<SecureStorage>(storage);
  }

  @override
  Future<SupportInfo> support(Registry registry) {
    return registry.read<SecureStorageSupport>().check();
  }

  @override
  Future<void> ready(Registry registry) async {
    final markerStorage = registry.readOrNull<Storage>();
    if (markerStorage == null) {
      return;
    }
    try {
      await FirstRunWipe(
        gateway: FlutterSecureStorageGateway(),
        storage: markerStorage,
      ).run(isIOS: defaultTargetPlatform == TargetPlatform.iOS);
    } on Object catch (error) {
      registry.read<SupportRegistry>().record(
        id,
        SupportInfo.unsupported(
          SupportState.unavailable,
          message: 'Secure storage could not be prepared: $error',
          details: <String, Object?>{'error': '$error'},
        ),
      );
    }
  }
}
