import 'package:kiln_core/kiln_core.dart';

/// Converts PostHog plugin errors into a [Failure].
final class AnalyticsFailureMapper {
  const AnalyticsFailureMapper();

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
