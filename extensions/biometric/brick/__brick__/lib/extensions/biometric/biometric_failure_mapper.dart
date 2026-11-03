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
      message: 'Biometrik tidak tersedia.',
      kind: FailureKind.unavailable,
      stackTrace: stackTrace,
    );
  }
  return switch (error.code) {
    LocalAuthExceptionCode.userCanceled ||
    LocalAuthExceptionCode.systemCanceled ||
    LocalAuthExceptionCode.timeout => Failure(
      code: FailureCode.cancelled,
      message: 'Autentikasi dibatalkan.',
      kind: FailureKind.cancelled,
      cause: error,
      stackTrace: stackTrace,
    ),
    LocalAuthExceptionCode.noCredentialsSet ||
    LocalAuthExceptionCode.noBiometricsEnrolled => Failure(
      code: FailureCode.permissionDenied,
      message: 'Biometrik belum terdaftar di perangkat.',
      kind: FailureKind.permission,
      cause: error,
      stackTrace: stackTrace,
    ),
    LocalAuthExceptionCode.noBiometricHardware ||
    LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable => Failure(
      code: FailureCode.unavailable,
      message: 'Perangkat tidak mendukung biometrik.',
      kind: FailureKind.unavailable,
      cause: error,
      stackTrace: stackTrace,
    ),
    LocalAuthExceptionCode.biometricLockout ||
    LocalAuthExceptionCode.temporaryLockout => Failure(
      code: FailureCode.permissionPermanentlyDenied,
      message: 'Biometrik terkunci. Coba lagi nanti atau pakai kode perangkat.',
      kind: FailureKind.permission,
      cause: error,
      stackTrace: stackTrace,
    ),
    LocalAuthExceptionCode.authInProgress ||
    LocalAuthExceptionCode.uiUnavailable => Failure(
      code: FailureCode.unavailable,
      message: 'Autentikasi tidak bisa dimulai sekarang.',
      kind: FailureKind.unavailable,
      cause: error,
      stackTrace: stackTrace,
      isRetryable: true,
    ),
    _ => Failure(
      code: FailureCode.unexpected,
      message: error.description ?? 'Autentikasi biometrik gagal.',
      kind: FailureKind.unknown,
      cause: error,
      stackTrace: stackTrace,
    ),
  };
}
