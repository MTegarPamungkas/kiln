import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/biometric/app_lock.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_config.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_gate.dart';

import 'test_support.dart';

({AppLock lock, FakeBiometricGateway gateway, FixedClock clock}) _build() {
  final gateway = FakeBiometricGateway();
  final clock = FixedClock(DateTime.utc(2026, 11, 2, 9));
  const config = BiometricConfig(gracePeriod: Duration(seconds: 30));
  final gate = BiometricGate(
    biometric: createBiometric(gateway: gateway),
    config: config,
    clock: clock,
  );
  return (
    lock: AppLock(gate: gate, config: config, clock: clock),
    gateway: gateway,
    clock: clock,
  );
}

void main() {
  test('locks after the pause exceeds the grace period', () async {
    final harness = _build();
    final start = harness.clock.now();

    harness.lock.onPause(start);
    await harness.lock.onResume(start.add(const Duration(seconds: 31)));

    expect(harness.lock.isLocked, isTrue);
  });

  test('stays unlocked for a short pause', () async {
    final harness = _build();
    final start = harness.clock.now();

    harness.lock.onPause(start);
    await harness.lock.onResume(start.add(const Duration(seconds: 10)));

    expect(harness.lock.isLocked, isFalse);
  });

  test('unlocks after a successful authentication', () async {
    final harness = _build();
    harness.lock.lock();

    expect(await harness.lock.unlock(), isTrue);
    expect(harness.lock.isLocked, isFalse);
    expect(harness.gateway.authCalls, 1);
  });

  test('stays locked when authentication fails', () async {
    final harness = _build();
    harness.gateway.result = false;
    harness.lock.lock();

    expect(await harness.lock.unlock(), isFalse);
    expect(harness.lock.isLocked, isTrue);
  });
}
