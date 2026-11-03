import 'package:kiln_core/kiln_core.dart';

/// Converts connectivity plugin errors into a Failure.
Failure mapConnectivityError(Object error, {StackTrace? stackTrace}) {
  if (error is Failure) {
    return error;
  }
  return Failure.from(
    error,
    code: FailureCode.unavailable,
    kind: FailureKind.unavailable,
    stackTrace: stackTrace,
  );
}
