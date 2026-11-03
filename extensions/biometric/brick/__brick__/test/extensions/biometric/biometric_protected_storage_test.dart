import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_protected_storage.dart';

import 'test_support.dart';

void main() {
  test('requires authentication before reading', () async {
    final gateway = FakeBiometricGateway();
    final storage = InMemorySecureStorage(<String, String>{'token': 'secret'});
    final protected = BiometricProtectedStorage(
      storage: storage,
      biometric: createBiometric(gateway: gateway),
    );

    expect(await protected.read('token'), 'secret');
    expect(gateway.authCalls, 1);
  });

  test('does not read when authentication fails', () async {
    final gateway = FakeBiometricGateway()..result = false;
    final protected = BiometricProtectedStorage(
      storage: InMemorySecureStorage(<String, String>{'token': 'secret'}),
      biometric: createBiometric(gateway: gateway),
    );

    await expectLater(
      protected.read('token'),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.permissionDenied,
        ),
      ),
    );
  });

  test('delegates writes without authentication', () async {
    final gateway = FakeBiometricGateway();
    final storage = InMemorySecureStorage();
    final protected = BiometricProtectedStorage(
      storage: storage,
      biometric: createBiometric(gateway: gateway),
    );

    await protected.write('token', 'value');

    expect(storage.snapshot['token'], 'value');
    expect(gateway.authCalls, 0);
  });
}
