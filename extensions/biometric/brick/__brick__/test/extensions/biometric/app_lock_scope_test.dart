import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/biometric/app_lock.dart';
import 'package:{{app_name}}/extensions/biometric/app_lock_scope.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_config.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_gate.dart';

import 'test_support.dart';

void main() {
  testWidgets('covers the app while locked and unlocks with biometrics', (
    tester,
  ) async {
    final gateway = FakeBiometricGateway();
    final gate = BiometricGate(
      biometric: createBiometric(gateway: gateway),
      config: const BiometricConfig(),
    );
    final lock = AppLock(gate: gate);

    await tester.pumpWidget(
      MaterialApp(
        home: AppLockScope(
          appLock: lock,
          child: const Scaffold(body: Text('Rahasia')),
        ),
      ),
    );

    expect(find.text('Rahasia'), findsOneWidget);
    expect(find.text('Aplikasi terkunci'), findsNothing);

    lock.lock();
    await tester.pump();

    expect(find.text('Aplikasi terkunci'), findsOneWidget);
    expect(find.text('Buka dengan biometrik'), findsOneWidget);

    await tester.tap(find.text('Buka dengan biometrik'));
    await tester.pumpAndSettle();

    expect(find.text('Aplikasi terkunci'), findsNothing);
    expect(find.text('Rahasia'), findsOneWidget);
    expect(gateway.authCalls, 1);
  });
}
