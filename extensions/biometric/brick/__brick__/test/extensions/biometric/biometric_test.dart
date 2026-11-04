import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_availability.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_config.dart';

import 'test_support.dart';

void main() {
  test('reports availability and enrolled methods', () async {
    final gateway = FakeBiometricGateway()
      ..methods = <BiometricMethod>[BiometricMethod.face];
    final biometric = createBiometric(gateway: gateway);

    expect(await biometric.availability(), BiometricAvailability.available);
    expect(await biometric.availableBiometrics(), [BiometricMethod.face]);
  });

  test('authenticates with the configured prompt', () async {
    final gateway = FakeBiometricGateway();
    final biometric = createBiometric(gateway: gateway);

    expect(await biometric.authenticate(), isTrue);
    expect(gateway.authCalls, 1);
    expect(gateway.lastReason, 'Unlock the app with biometrics');
    expect(gateway.lastBiometricOnly, isTrue);
  });

  test('reports a failed challenge as false', () async {
    final biometric = createBiometric(
      gateway: FakeBiometricGateway()..result = false,
    );

    expect(await biometric.authenticate(), isFalse);
  });

  test('rejects platforms without support', () async {
    final biometric = createBiometric(platform: TargetPlatform.linux);

    await expectLater(
      biometric.authenticate(),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.unsupportedPlatform,
        ),
      ),
    );
  });

  test('rejects devices without enrolled biometrics', () async {
    final biometric = createBiometric(
      gateway: FakeBiometricGateway()..methods = <BiometricMethod>[],
    );

    await expectLater(
      biometric.authenticate(),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.permissionDenied,
        ),
      ),
    );
  });

  test('uses the configured reason and fallback policy', () async {
    final gateway = FakeBiometricGateway();
    final biometric = createBiometric(
      gateway: gateway,
      config: const BiometricConfig(
        reason: 'Buka brankas',
        biometricOnly: false,
      ),
    );

    await biometric.authenticate();

    expect(gateway.lastReason, 'Buka brankas');
    expect(gateway.lastBiometricOnly, isFalse);
  });
}
