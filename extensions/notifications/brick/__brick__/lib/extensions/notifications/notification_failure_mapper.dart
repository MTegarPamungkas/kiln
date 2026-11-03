import 'package:kiln_core/kiln_core.dart';

/// Converts notification plugin errors into a Failure.
Failure mapNotificationError(Object error, {StackTrace? stackTrace}) {
  if (error is Failure) {
    return error;
  }
  return Failure.from(
    error,
    code: FailureCode.notificationsUnavailable,
    kind: FailureKind.notification,
    stackTrace: stackTrace,
  );
}
