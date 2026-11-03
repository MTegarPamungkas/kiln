import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:local_auth/local_auth.dart';
import 'package:{{app_name}}/extensions/biometric/biometric_failure_mapper.dart';

void main() {
  test('maps cancellation and lockout codes', () {
    final cancelled = mapBiometricError(
      const LocalAuthException(code: LocalAuthExceptionCode.userCanceled),
    );
    final lockedOut = mapBiometricError(
      const LocalAuthException(code: LocalAuthExceptionCode.biometricLockout),
    );

    expect(cancelled.code, FailureCode.cancelled);
    expect(cancelled.kind, FailureKind.cancelled);
    expect(lockedOut.code, FailureCode.permissionPermanentlyDenied);
  });

  test('maps missing enrollment and hardware', () {
    final notEnrolled = mapBiometricError(
      const LocalAuthException(
        code: LocalAuthExceptionCode.noBiometricsEnrolled,
      ),
    );
    final noHardware = mapBiometricError(
      const LocalAuthException(
        code: LocalAuthExceptionCode.noBiometricHardware,
      ),
    );

    expect(notEnrolled.code, FailureCode.permissionDenied);
    expect(noHardware.code, FailureCode.unsupportedDevice);
  });

  test('keeps a Failure and wraps platform errors', () {
    const original = Failure(code: FailureCode.unavailable, message: 'nope');

    expect(mapBiometricError(original), same(original));
    expect(
      mapBiometricError(PlatformException(code: 'x')).code,
      FailureCode.unavailable,
    );
  });
}
