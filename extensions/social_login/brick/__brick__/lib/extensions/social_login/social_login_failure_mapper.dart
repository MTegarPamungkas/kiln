import 'package:flutter/services.dart';
import 'package:kiln_core/kiln_core.dart';

/// Converts Google and Apple SDK errors into a Failure.
Failure mapSocialLoginError(Object error, {StackTrace? stackTrace}) {
  if (error is Failure) {
    return error;
  }
  if (error is PlatformException) {
    final code = error.code.toLowerCase();
    final message = error.message?.toLowerCase() ?? '';
    if (code.contains('cancel') ||
        code.contains('canceled') ||
        message.contains('cancel')) {
      return Failure(
        code: FailureCode.authCancelled,
        message: 'Masuk dibatalkan.',
        kind: FailureKind.cancelled,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (code.contains('network') || message.contains('network')) {
      return Failure(
        code: FailureCode.networkUnreachable,
        message: 'Jaringan tidak tersedia.',
        kind: FailureKind.network,
        cause: error,
        stackTrace: stackTrace,
        isRetryable: true,
      );
    }
    return Failure(
      code: FailureCode.authProviderDisabled,
      message: error.message ?? 'Masuk dengan penyedia ini gagal.',
      kind: FailureKind.authentication,
      cause: error,
      stackTrace: stackTrace,
    );
  }
  final text = error.toString().toLowerCase();
  if (text.contains('cancel')) {
    return Failure(
      code: FailureCode.authCancelled,
      message: 'Masuk dibatalkan.',
      kind: FailureKind.cancelled,
      cause: error,
      stackTrace: stackTrace,
    );
  }
  return Failure.from(
    error,
    code: FailureCode.authProviderDisabled,
    kind: FailureKind.authentication,
    stackTrace: stackTrace,
  );
}
