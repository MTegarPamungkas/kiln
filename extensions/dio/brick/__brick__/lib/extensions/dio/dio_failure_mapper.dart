import 'package:dio/dio.dart';
import 'package:kiln_core/kiln_core.dart';

/// Converts every dio failure into the shared [Failure] model.
Failure mapDioException(DioException error) {
  final original = error.error;
  if (original is Failure) {
    return original;
  }

  final statusCode = error.response?.statusCode;
  if (statusCode != null) {
    return _mapResponse(error, statusCode);
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => Failure(
      code: FailureCode.networkTimeout,
      message: 'The request timed out',
      kind: FailureKind.network,
      cause: error,
      stackTrace: error.stackTrace,
      isRetryable: true,
    ),
    DioExceptionType.connectionError => Failure(
      code: FailureCode.networkUnreachable,
      message: 'The server could not be reached',
      kind: FailureKind.network,
      cause: error,
      stackTrace: error.stackTrace,
      isRetryable: true,
    ),
    DioExceptionType.cancel => Failure(
      code: FailureCode.cancelled,
      message: 'The request was cancelled',
      kind: FailureKind.cancelled,
      cause: error,
      stackTrace: error.stackTrace,
    ),
    DioExceptionType.badCertificate => Failure(
      code: FailureCode.networkUnreachable,
      message: 'The server certificate is not trusted',
      kind: FailureKind.network,
      cause: error,
      stackTrace: error.stackTrace,
    ),
    DioExceptionType.badResponse => Failure(
      code: FailureCode.networkServer,
      message: 'The server returned an invalid response',
      kind: FailureKind.network,
      cause: error,
      stackTrace: error.stackTrace,
      isRetryable: true,
    ),
    DioExceptionType.unknown => Failure(
      code: FailureCode.networkUnknown,
      message: error.message ?? 'The request failed',
      kind: FailureKind.network,
      cause: error,
      stackTrace: error.stackTrace,
    ),
  };
}

Failure _mapResponse(DioException error, int statusCode) {
  final serverMessage = _serverMessage(error.response?.data);
  final retryAfter = _retryAfter(error.response?.headers);
  final details = <String, Object?>{'statusCode': statusCode};
  if (serverMessage != null) {
    details['serverMessage'] = serverMessage;
  }
  if (retryAfter != null) {
    details['retryAfterSeconds'] = retryAfter;
  }

  if (statusCode == 401 || statusCode == 403) {
    return Failure(
      code: FailureCode.authUnauthorized,
      message: serverMessage ?? 'The request was not authorized',
      kind: FailureKind.authorization,
      cause: error,
      stackTrace: error.stackTrace,
      details: details,
    );
  }
  if (statusCode == 404) {
    return Failure(
      code: FailureCode.unavailable,
      message: serverMessage ?? 'The requested resource was not found',
      kind: FailureKind.unavailable,
      cause: error,
      stackTrace: error.stackTrace,
      details: details,
    );
  }
  if (statusCode == 408) {
    return Failure(
      code: FailureCode.networkTimeout,
      message: serverMessage ?? 'The request timed out',
      kind: FailureKind.network,
      cause: error,
      stackTrace: error.stackTrace,
      details: details,
      isRetryable: true,
    );
  }
  if (statusCode == 429) {
    return Failure(
      code: FailureCode.networkServer,
      message: serverMessage ?? 'The server is rate limiting requests',
      kind: FailureKind.network,
      cause: error,
      stackTrace: error.stackTrace,
      details: details,
      isRetryable: true,
    );
  }
  if (statusCode >= 500) {
    return Failure(
      code: FailureCode.networkServer,
      message: serverMessage ?? 'The server could not complete the request',
      kind: FailureKind.network,
      cause: error,
      stackTrace: error.stackTrace,
      details: details,
      isRetryable: true,
    );
  }
  return Failure(
    code: FailureCode.validationInvalidInput,
    message:
        serverMessage ?? 'The request was rejected with status $statusCode',
    kind: FailureKind.validation,
    cause: error,
    stackTrace: error.stackTrace,
    details: details,
  );
}

/// Reads a short, human-readable message without exposing the raw body.
String? _serverMessage(Object? data) {
  String? candidate;
  if (data is Map) {
    for (final key in <String>['message', 'error', 'detail']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        candidate = value;
        break;
      }
    }
  } else if (data is String) {
    candidate = data;
  }
  if (candidate == null) {
    return null;
  }
  final trimmed = candidate.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return trimmed.length <= 300 ? trimmed : '${trimmed.substring(0, 300)}…';
}

int? _retryAfter(Headers? headers) {
  final raw = headers?.value('retry-after');
  if (raw == null) {
    return null;
  }
  return int.tryParse(raw.trim());
}
