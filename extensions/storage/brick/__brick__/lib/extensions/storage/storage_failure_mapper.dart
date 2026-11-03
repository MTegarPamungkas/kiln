import 'package:kiln_core/kiln_core.dart';

/// Converts plugin and cast errors into a storage [Failure].
Failure mapStorageError(
  Object error, {
  StackTrace? stackTrace,
  FailureCode code = FailureCode.storageReadFailed,
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
