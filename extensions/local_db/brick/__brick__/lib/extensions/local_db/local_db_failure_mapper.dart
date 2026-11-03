import 'package:kiln_core/kiln_core.dart';

/// Converts Sembast and plugin errors into a database [Failure].
Failure mapLocalDbError(
  Object error, {
  StackTrace? stackTrace,
  FailureCode code = FailureCode.databaseQueryFailed,
}) {
  if (error is Failure) {
    return error;
  }
  return Failure.from(
    error,
    code: code,
    kind: FailureKind.database,
    stackTrace: stackTrace,
  );
}
