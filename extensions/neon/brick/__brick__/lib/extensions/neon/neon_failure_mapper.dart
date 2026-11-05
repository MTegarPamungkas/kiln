import 'package:kiln_core/kiln_core.dart';

import 'neon_gateway.dart';

/// Converts Neon Data API errors into a [Failure].
///
/// A [NeonApiException] becomes a database failure whose code reflects the HTTP
/// status (5xx or transport -> unavailable, 404 -> notFound, otherwise the query
/// failure); a [Failure] passes through untouched.
Failure mapNeonError(
  Object error, {
  FailureCode fallbackCode = FailureCode.remoteDatabaseUnavailable,
  FailureKind fallbackKind = FailureKind.database,
  StackTrace? stackTrace,
}) {
  if (error is Failure) {
    return error;
  }
  if (error is NeonApiException) {
    final status = error.statusCode;
    final code = status == null
        ? fallbackCode
        : switch (status) {
            404 => FailureCode.remoteDatabaseNotFound,
            >= 500 => FailureCode.remoteDatabaseUnavailable,
            _ => FailureCode.remoteDatabaseQueryFailed,
          };
    return Failure(
      code: code,
      message: error.message,
      kind: FailureKind.database,
      details: <String, Object?>{
        if (status != null) 'statusCode': status,
        if (error.code != null) 'code': error.code,
      },
    );
  }
  return Failure.from(
    error,
    code: fallbackCode,
    kind: fallbackKind,
    stackTrace: stackTrace,
  );
}
