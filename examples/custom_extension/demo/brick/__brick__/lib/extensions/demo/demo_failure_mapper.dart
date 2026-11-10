import 'package:kiln_core/kiln_core.dart';

/// Converts errors from the underlying package into [Failure].
Failure mapDemoError(Object error, {StackTrace? stackTrace}) {
  if (error is Failure) {
    return error;
  }
  return Failure.from(
    error,
    code: FailureCode.unexpected,
    kind: FailureKind.unknown,
    stackTrace: stackTrace,
  );
}
