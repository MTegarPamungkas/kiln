import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:kiln_core/kiln_core.dart';

/// Maps every geolocator error to the shared [Failure] model.
Failure mapGeolocationError(
  Object error, {
  StackTrace? stackTrace,
  String? message,
}) {
  if (error is Failure) {
    return error;
  }
  if (error is TimeoutException) {
    return Failure(
      code: FailureCode.unavailable,
      message: message ?? 'Location request timed out.',
      kind: FailureKind.unavailable,
      cause: error,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }
  if (error is geo.LocationServiceDisabledException) {
    return Failure(
      code: FailureCode.unavailable,
      message: message ?? 'Location services are disabled on this device.',
      kind: FailureKind.unavailable,
      cause: error,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }
  if (error is geo.PermissionDeniedException) {
    return Failure(
      code: FailureCode.permissionDenied,
      message: message ?? 'Location permission is denied.',
      kind: FailureKind.permission,
      cause: error,
      stackTrace: stackTrace,
    );
  }
  return Failure(
    code: FailureCode.unavailable,
    message: message ?? 'Location is unavailable: $error',
    kind: FailureKind.unavailable,
    cause: error,
    stackTrace: stackTrace,
    isRetryable: true,
  );
}
