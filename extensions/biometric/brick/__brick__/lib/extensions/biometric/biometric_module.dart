import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';

import 'app_lock.dart';
import 'app_lock_scope.dart';
import 'biometric.dart';
import 'biometric_config.dart';
import 'biometric_gate.dart';
import 'biometric_gateway.dart';
import 'biometric_protected_storage.dart';

typedef AppWrapper = Widget Function(BuildContext context, Widget child);

/// Registers Biometric, the app lock, and their seams.
final class BiometricModule extends KilnModule {
  const BiometricModule();

  @override
  String get id => 'biometric';

  @override
  Set<String> get platforms => const <String>{'android', 'ios', 'macos'};

  @override
  Set<String> get provides => const <String>{'biometric'};

  @override
  void register(Registry registry) {
    const config = BiometricConfig.defaults;
    final clock = registry.readOrNull<Clock>() ?? const SystemClock();
    final gateway = SdkBiometricGateway();
    final biometric = Biometric(gateway: gateway, config: config);
    final gate = BiometricGate(
      biometric: biometric,
      config: config,
      clock: clock,
    );
    final appLock = AppLock(gate: gate, config: config, clock: clock);

    registry
      ..registerSingleton<BiometricConfig>(config)
      ..registerSingleton<BiometricGateway>(gateway)
      ..registerSingleton<Biometric>(biometric)
      ..registerSingleton<BiometricGate>(gate)
      ..registerSingleton<AppLock>(appLock);

    final slots = registry.readOrNull<SlotRegistry>();
    slots
        ?.open<AppWrapper>(SlotNames.appWrappers)
        .add(
          (context, child) => AppLockScope(appLock: appLock, child: child),
          owner: 'biometric',
        );

    final storage = registry.readOrNull<SecureStorage>();
    if (storage != null) {
      registry.registerSingleton<BiometricProtectedStorage>(
        BiometricProtectedStorage(storage: storage, biometric: biometric),
      );
    }
  }
}
