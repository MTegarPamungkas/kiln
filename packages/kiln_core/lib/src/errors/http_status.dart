import 'failure.dart';
import 'failure_codes.dart';

/// Common HTTP status codes used by Kiln contracts.
///
/// Kept in the core so every backend extension shares one set of constants
/// instead of redefining them.
final class HttpStatusCodes {
  const HttpStatusCodes._();

  static const ok = 200;
  static const created = 201;
  static const accepted = 202;
  static const noContent = 204;

  static const badRequest = 400;
  static const unauthorized = 401;
  static const forbidden = 403;
  static const notFound = 404;
  static const methodNotAllowed = 405;
  static const conflict = 409;
  static const tooManyRequests = 429;

  static const internalServerError = 500;
  static const badGateway = 502;
  static const serviceUnavailable = 503;
  static const gatewayTimeout = 504;
}

/// Whether a response status is safe to retry with backoff.
bool isRetryableHttpStatus(int statusCode) =>
    statusCode == 408 ||
    statusCode == HttpStatusCodes.tooManyRequests ||
    statusCode >= 500;

/// Maps an HTTP response status to the shared [Failure] model.
///
/// Every HTTP transport should route non-2xx responses through this function
/// so a status code means the same thing across backends.
Failure mapHttpStatusToFailure(
  int statusCode, {
  String? message,
  Object? cause,
  StackTrace? stackTrace,
  Map<String, Object?>? details,
}) {
  final merged = <String, Object?>{'statusCode': statusCode, ...?details};

  if (statusCode == HttpStatusCodes.unauthorized ||
      statusCode == HttpStatusCodes.forbidden) {
    return Failure(
      code: FailureCode.authUnauthorized,
      message: message ?? 'The request was not authorized',
      kind: FailureKind.authorization,
      cause: cause,
      stackTrace: stackTrace,
      details: merged,
    );
  }
  if (statusCode == HttpStatusCodes.notFound) {
    return Failure(
      code: FailureCode.unavailable,
      message: message ?? 'The requested resource was not found',
      kind: FailureKind.unavailable,
      cause: cause,
      stackTrace: stackTrace,
      details: merged,
    );
  }
  if (statusCode == 408) {
    return Failure(
      code: FailureCode.networkTimeout,
      message: message ?? 'The request timed out',
      kind: FailureKind.network,
      cause: cause,
      stackTrace: stackTrace,
      details: merged,
      isRetryable: true,
    );
  }
  if (statusCode == HttpStatusCodes.tooManyRequests) {
    return Failure(
      code: FailureCode.networkServer,
      message: message ?? 'The server is rate limiting requests',
      kind: FailureKind.network,
      cause: cause,
      stackTrace: stackTrace,
      details: merged,
      isRetryable: true,
    );
  }
  if (statusCode >= 500) {
    return Failure(
      code: FailureCode.networkServer,
      message: message ?? 'The server could not complete the request',
      kind: FailureKind.network,
      cause: cause,
      stackTrace: stackTrace,
      details: merged,
      isRetryable: true,
    );
  }
  return Failure(
    code: FailureCode.validationInvalidInput,
    message: message ?? 'The request was rejected with status $statusCode',
    kind: FailureKind.validation,
    cause: cause,
    stackTrace: stackTrace,
    details: merged,
  );
}
