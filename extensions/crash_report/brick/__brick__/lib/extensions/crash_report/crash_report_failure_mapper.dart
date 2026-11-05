import 'package:kiln_core/kiln_core.dart';

/// Converts Sentry plugin errors into a [Failure].
final class CrashReportFailureMapper {
  const CrashReportFailureMapper();

  Failure map(Object error, {StackTrace? stackTrace}) {
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
}
