import 'package:kiln_core/kiln_core.dart';

/// Converts plugin and parse errors into a deep link [Failure].
Failure mapDeepLinkError(Object error, {StackTrace? stackTrace}) {
  if (error is Failure) {
    return error;
  }
  if (error is FormatException) {
    return Failure(
      code: FailureCode.deepLinkInvalid,
      message: 'Tautan masuk tidak valid.',
      kind: FailureKind.deepLink,
      cause: error,
      stackTrace: stackTrace,
    );
  }
  return Failure(
    code: FailureCode.deepLinkUnavailable,
    message: 'Tautan masuk tidak dapat dibaca dari platform.',
    kind: FailureKind.deepLink,
    cause: error,
    stackTrace: stackTrace,
  );
}
