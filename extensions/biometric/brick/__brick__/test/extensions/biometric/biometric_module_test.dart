import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/biometric/app_lock.dart';
import 'package:{{app_name}}/extensions/biometric/biometric.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_config.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_gate.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_gateway.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_module.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_protected_storage.dart';

void main() {
  test('module registers biometrics and the lock without injecting UI', () {
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<SecureStorage>(InMemorySecureStorage());

    const BiometricModule().register(registry);

    expect(registry.read<Biometric>(), isA<Biometric>());
    expect(registry.read<BiometricConfig>(), isA<BiometricConfig>());
    expect(registry.read<BiometricGateway>(), isA<BiometricGateway>());
    expect(registry.read<BiometricGate>(), isA<BiometricGate>());
    expect(registry.read<AppLock>(), isA<AppLock>());
    expect(
      registry.read<BiometricProtectedStorage>(),
      isA<BiometricProtectedStorage>(),
    );
    expect(
      registry.read<SlotRegistry>().has(SlotNames.appWrappers),
      isFalse,
    );
  });

  test('module skips protected storage without SecureStorage', () {
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry());

    const BiometricModule().register(registry);

    expect(registry.readOrNull<BiometricProtectedStorage>(), isNull);
  });
}
