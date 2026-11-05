import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/biometric/app_lock.dart';
import 'package:{{app_name}}/extensions/biometric/biometric.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_availability.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_gate.dart';
import 'package:{{app_name}}/extensions/biometric/gate_biometric.dart';

import 'test_support.dart';

void main() {
  test('gate exposes biometric one-call results', () async {
    final biometric = createBiometric();
    final registry = GetItRegistry()
      ..registerSingleton<Biometric>(biometric)
      ..registerSingleton<AppLock>(
        AppLock(gate: BiometricGate(biometric: biometric)),
      );
    final gate = Gate(registry);

    final availability = await gate.biometricAvailability();
    expect(availability, isA<Ok<BiometricAvailability>>());
    expect(availability.valueOrNull, BiometricAvailability.available);

    final authenticated = await gate.biometricAuthenticate();
    expect(authenticated.valueOrNull, isTrue);
  });

  test('biometric authenticate surfaces failures as Err', () async {
    final gateway = FakeBiometricGateway()
      ..failure = const Failure(
        code: FailureCode.permissionDenied,
        message: 'x',
      );
    final registry = GetItRegistry()
      ..registerSingleton<Biometric>(createBiometric(gateway: gateway));
    final gate = Gate(registry);

    final result = await gate.biometricAuthenticate();

    expect(result, isA<Err<bool>>());
  });

  test('biometric unlock reports Ok(false) when the challenge fails', () async {
    final gateway = FakeBiometricGateway()..result = false;
    final biometric = createBiometric(gateway: gateway);
    final registry = GetItRegistry()
      ..registerSingleton<Biometric>(biometric)
      ..registerSingleton<AppLock>(
        AppLock(gate: BiometricGate(biometric: biometric)),
      );
    final gate = Gate(registry);
    await gate.appLock.initialize();
    gate.appLock.lock();

    final result = await gate.biometricUnlock();

    expect(result.valueOrNull, isFalse);
  });
}
