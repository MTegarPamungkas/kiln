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
    if (statusCode == 401 || statusCode == 403) {
      return Failure(
        code: FailureCode.authUnauthorized,
        message: 'The request was not authorized',
        kind: FailureKind.authorization,
        cause: error,
        stackTrace: error.stackTrace,
        details: {'statusCode': statusCode},
      );
    }
    if (statusCode >= 500) {
      return Failure(
        code: FailureCode.networkServer,
        message: 'The server could not complete the request',
        kind: FailureKind.network,
        cause: error,
        stackTrace: error.stackTrace,
        details: {'statusCode': statusCode},
        isRetryable: true,
      );
    }
    return Failure(
      code: FailureCode.validationInvalidInput,
      message: 'The request was rejected with status $statusCode',
      kind: FailureKind.validation,
      cause: error,
      stackTrace: error.stackTrace,
      details: {'statusCode': statusCode},
    );
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
