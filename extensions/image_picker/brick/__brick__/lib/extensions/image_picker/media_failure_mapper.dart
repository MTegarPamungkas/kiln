import 'package:flutter/services.dart';
import 'package:kiln_core/kiln_core.dart';

/// Converts image_picker errors into a Failure.
Failure mapMediaError(Object error, {StackTrace? stackTrace}) {
  if (error is Failure) {
    return error;
  }
  if (error is MissingPluginException || error is UnsupportedError) {
    return const SupportInfo.unsupported(
      SupportState.unsupportedPlatform,
      message: 'Image picking is not supported on this platform.',
    ).toFailure();
  }
  if (error is PlatformException) {
    final code = error.code.toLowerCase();
    final message = error.message?.toLowerCase() ?? '';
    if (code.contains('access_denied') ||
        code.contains('permission') ||
        message.contains('permission')) {
      return Failure(
        code: FailureCode.mediaPermissionDenied,
        message: error.message ?? 'Camera or gallery permission was denied.',
        kind: FailureKind.permission,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (code.contains('cancel') || message.contains('cancel')) {
      return Failure(
        code: FailureCode.mediaCancelled,
        message: 'Image selection was cancelled.',
        kind: FailureKind.cancelled,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
  final message = error.toString().toLowerCase();
  if (message.contains('cancelled') || message.contains('canceled')) {
    return Failure(
      code: FailureCode.mediaCancelled,
      message: 'Image selection was cancelled.',
      kind: FailureKind.cancelled,
      cause: error,
      stackTrace: stackTrace,
    );
  }
  return Failure.from(
    error,
    code: FailureCode.mediaUnavailable,
    kind: FailureKind.media,
    stackTrace: stackTrace,
  );
}
