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
  return mapHttpStatusToFailure(
    statusCode,
    message: serverMessage,
    cause: error,
    stackTrace: error.stackTrace,
    details: <String, Object?>{
      'serverMessage': ?serverMessage,
      'retryAfterSeconds': ?retryAfter,
    },
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
