import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_config.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_gate.dart';

import 'test_support.dart';

void main() {
  test('authenticates before running the action', () async {
    final gateway = FakeBiometricGateway();
    final biometric = createBiometric(gateway: gateway);
    final gate = BiometricGate(
      biometric: biometric,
      config: const BiometricConfig(gracePeriod: Duration(seconds: 30)),
      clock: FixedClock(DateTime.utc(2026, 11, 2, 9)),
    );
    var runs = 0;

    final value = await gate.guard(() async {
      runs++;
      return 42;
    });

    expect(value, 42);
    expect(runs, 1);
    expect(gateway.authCalls, 1);
  });

  test('reuses the grace period and expires it', () async {
    final gateway = FakeBiometricGateway();
    final clock = FixedClock(DateTime.utc(2026, 11, 2, 9));
    final gate = BiometricGate(
      biometric: createBiometric(gateway: gateway),
      config: const BiometricConfig(gracePeriod: Duration(seconds: 30)),
      clock: clock,
    );

    await gate.ensureAuthenticated();
    clock.advance(const Duration(seconds: 10));
    await gate.ensureAuthenticated();
    expect(gateway.authCalls, 1);

    clock.advance(const Duration(seconds: 25));
    await gate.ensureAuthenticated();
    expect(gateway.authCalls, 2);
  });

  test('does not run the action when authentication fails', () async {
    final gate = BiometricGate(
      biometric: createBiometric(
        gateway: FakeBiometricGateway()..result = false,
      ),
    );
    var runs = 0;

    await expectLater(
      gate.guard(() async => runs++),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.permissionDenied,
        ),
      ),
    );
    expect(runs, 0);
  });
}
