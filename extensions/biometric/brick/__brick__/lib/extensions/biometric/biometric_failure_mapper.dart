import 'package:kiln_core/kiln_core.dart';
import 'package:local_auth/local_auth.dart';

/// Converts local_auth errors into a Failure with a friendly message.
Failure mapBiometricError(Object error, {StackTrace? stackTrace}) {
  if (error is Failure) {
    return error;
  }
  if (error is! LocalAuthException) {
    return Failure.from(
      error,
      code: FailureCode.unavailable,
      message: 'Biometrics are not available.',
      kind: FailureKind.unavailable,
      stackTrace: stackTrace,
    );
  }
  return switch (error.code) {
    LocalAuthExceptionCode.userCanceled ||
    LocalAuthExceptionCode.systemCanceled ||
    LocalAuthExceptionCode.timeout => Failure(
      code: FailureCode.cancelled,
      message: 'Authentication was cancelled.',
      kind: FailureKind.cancelled,
      cause: error,
      stackTrace: stackTrace,
    ),
    LocalAuthExceptionCode.noCredentialsSet ||
    LocalAuthExceptionCode.noBiometricsEnrolled => Failure(
      code: FailureCode.permissionDenied,
      message: 'No biometrics are enrolled on this device.',
      kind: FailureKind.permission,
      cause: error,
      stackTrace: stackTrace,
    ),
    LocalAuthExceptionCode.noBiometricHardware => Failure(
      code: FailureCode.unsupportedDevice,
      message: 'This device has no biometric hardware.',
      kind: FailureKind.unsupported,
      cause: error,
      stackTrace: stackTrace,
    ),
    LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable => Failure(
      code: FailureCode.unavailable,
      message: 'Biometric hardware is temporarily unavailable.',
      kind: FailureKind.unavailable,
      cause: error,
      stackTrace: stackTrace,
    ),
    LocalAuthExceptionCode.biometricLockout ||
    LocalAuthExceptionCode.temporaryLockout => Failure(
      code: FailureCode.permissionPermanentlyDenied,
      message: 'Biometrics are locked. Try again later or use the device passcode.',
      kind: FailureKind.permission,
      cause: error,
      stackTrace: stackTrace,
    ),
    LocalAuthExceptionCode.authInProgress ||
    LocalAuthExceptionCode.uiUnavailable => Failure(
      code: FailureCode.unavailable,
      message: 'Authentication cannot start right now.',
      kind: FailureKind.unavailable,
      cause: error,
      stackTrace: stackTrace,
      isRetryable: true,
    ),
    _ => Failure(
      code: FailureCode.unexpected,
      message: error.description ?? 'Biometric authentication failed.',
      kind: FailureKind.unknown,
      cause: error,
      stackTrace: stackTrace,
    ),
  };
}
