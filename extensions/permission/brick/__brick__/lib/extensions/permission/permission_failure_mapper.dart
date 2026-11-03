import 'package:kiln_core/kiln_core.dart';

/// Converts permission_handler errors into a Failure.
Failure mapPermissionError(Object error, {StackTrace? stackTrace}) {
  if (error is Failure) {
    return error;
  }
  return Failure.from(
    error,
    code: FailureCode.permissionDenied,
    kind: FailureKind.permission,
    stackTrace: stackTrace,
  );
}
