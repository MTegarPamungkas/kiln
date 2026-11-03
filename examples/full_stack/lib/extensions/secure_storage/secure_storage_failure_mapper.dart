import 'package:kiln_core/kiln_core.dart';

/// Converts plugin errors into a secure-storage [Failure].
Failure mapSecureStorageError(
  Object error, {
  StackTrace? stackTrace,
  FailureCode code = FailureCode.secureStorageReadFailed,
}) {
  if (error is Failure) {
    return error;
  }
  return Failure.from(
    error,
    code: code,
    kind: FailureKind.storage,
    stackTrace: stackTrace,
  );
}
