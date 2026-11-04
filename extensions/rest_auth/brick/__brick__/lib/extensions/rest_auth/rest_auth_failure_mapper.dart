import 'package:kiln_core/kiln_core.dart';

/// Converts a non-successful HTTP response into a Failure.
Failure mapRestResponse(HttpResponse response) {
  final message = _message(response.data);
  final status = response.statusCode;
  if (status == 401) {
    return Failure(
      code: FailureCode.authSessionExpired,
      message: message ?? 'The session expired. Please sign in again.',
      kind: FailureKind.authentication,
      details: <String, Object?>{'status': status},
    );
  }
  if (status == 400 || status == 422) {
    return Failure(
      code: FailureCode.validationInvalidInput,
      message: message ?? 'The submitted data is not valid.',
      kind: FailureKind.validation,
      details: <String, Object?>{'status': status},
    );
  }
  if (status == 409) {
    return Failure(
      code: FailureCode.validationInvalidInput,
      message: message ?? 'The data has already been used.',
      kind: FailureKind.validation,
      details: <String, Object?>{'status': status},
    );
  }
  if (status == 403 || status == 404 || status == 429 || status >= 500) {
    final fallback = switch (status) {
      403 => 'Akses ditolak.',
      404 => 'The endpoint was not found.',
      _ => 'Server sedang sibuk.',
    };
    return mapHttpStatusToFailure(
      status,
      message: message ?? fallback,
      details: <String, Object?>{'status': status},
    );
  }
  return Failure(
    code: FailureCode.unexpected,
    message: message ?? 'The request failed (status $status).',
    kind: FailureKind.unknown,
    details: <String, Object?>{'status': status},
  );
}

/// Login and register treat a 401 as invalid credentials.
Failure mapCredentialResponse(HttpResponse response) {
  if (response.statusCode == 401) {
    return Failure(
      code: FailureCode.authInvalidCredentials,
      message: _message(response.data) ?? 'The email or password is incorrect.',
      kind: FailureKind.authentication,
      details: <String, Object?>{'status': response.statusCode},
    );
  }
  return mapRestResponse(response);
}

String? _message(Object? data) {
  if (data is Map) {
    for (final key in const <String>[
      'message',
      'error_description',
      'error',
      'detail',
    ]) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
      if (value is Map && value['message'] is String) {
        return value['message'] as String;
      }
    }
  }
  if (data is String && data.trim().isNotEmpty) {
    return data;
  }
  return null;
}
