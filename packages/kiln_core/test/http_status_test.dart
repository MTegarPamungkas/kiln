import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

void main() {
  group('HttpStatusCodes', () {
    test('exposes common status codes', () {
      expect(HttpStatusCodes.ok, 200);
      expect(HttpStatusCodes.created, 201);
      expect(HttpStatusCodes.unauthorized, 401);
      expect(HttpStatusCodes.forbidden, 403);
      expect(HttpStatusCodes.notFound, 404);
      expect(HttpStatusCodes.conflict, 409);
      expect(HttpStatusCodes.tooManyRequests, 429);
      expect(HttpStatusCodes.serviceUnavailable, 503);
    });
  });

  group('isRetryableHttpStatus', () {
    test('marks 408, 429, and 5xx as retryable', () {
      expect(isRetryableHttpStatus(408), isTrue);
      expect(isRetryableHttpStatus(429), isTrue);
      expect(isRetryableHttpStatus(500), isTrue);
      expect(isRetryableHttpStatus(503), isTrue);
    });

    test('marks other statuses as not retryable', () {
      expect(isRetryableHttpStatus(200), isFalse);
      expect(isRetryableHttpStatus(400), isFalse);
      expect(isRetryableHttpStatus(401), isFalse);
      expect(isRetryableHttpStatus(404), isFalse);
      expect(isRetryableHttpStatus(409), isFalse);
    });
  });

  group('mapHttpStatusToFailure', () {
    test('maps 401 and 403 to authorization failures', () {
      for (final status in [401, 403]) {
        final failure = mapHttpStatusToFailure(status);
        expect(failure.code, FailureCode.authUnauthorized);
        expect(failure.kind, FailureKind.authorization);
        expect(failure.details['statusCode'], status);
      }
    });

    test('maps 404 to unavailable', () {
      final failure = mapHttpStatusToFailure(404);
      expect(failure.code, FailureCode.unavailable);
      expect(failure.kind, FailureKind.unavailable);
    });

    test('maps 408 to a retryable timeout', () {
      final failure = mapHttpStatusToFailure(408);
      expect(failure.code, FailureCode.networkTimeout);
      expect(failure.kind, FailureKind.network);
      expect(failure.isRetryable, isTrue);
    });

    test('maps 429 to a retryable server failure', () {
      final failure = mapHttpStatusToFailure(429);
      expect(failure.code, FailureCode.networkServer);
      expect(failure.isRetryable, isTrue);
    });

    test('maps every 5xx to a retryable server failure', () {
      for (final status in [500, 502, 503, 504]) {
        final failure = mapHttpStatusToFailure(status);
        expect(failure.code, FailureCode.networkServer);
        expect(failure.isRetryable, isTrue);
      }
    });

    test('maps other 4xx to validation failures', () {
      final failure = mapHttpStatusToFailure(400);
      expect(failure.code, FailureCode.validationInvalidInput);
      expect(failure.kind, FailureKind.validation);
      expect(failure.isRetryable, isFalse);
    });

    test('prefers a supplied message and merges details', () {
      final failure = mapHttpStatusToFailure(
        503,
        message: 'Down for maintenance',
        details: {'retryAfterSeconds': 30},
      );
      expect(failure.message, 'Down for maintenance');
      expect(failure.details['retryAfterSeconds'], 30);
      expect(failure.details['statusCode'], 503);
    });
  });
}
