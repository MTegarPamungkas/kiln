import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/dio/dio_failure_mapper.dart';

DioException _exception(
  DioExceptionType type, {
  int? statusCode,
  Object? data,
  Map<String, List<String>>? headers,
}) {
  final options = RequestOptions(path: 'https://api.kiln.dev');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response<Object?>(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
            headers: headers == null ? null : Headers.fromMap(headers),
          ),
  );
}

void main() {
  test('maps every timeout type to networkTimeout', () {
    for (final type in <DioExceptionType>[
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      final failure = mapDioException(_exception(type));

      expect(failure.code, FailureCode.networkTimeout);
      expect(failure.isRetryable, isTrue);
    }
  });

  test('maps a connection error to networkUnreachable', () {
    final failure = mapDioException(
      _exception(DioExceptionType.connectionError),
    );

    expect(failure.code, FailureCode.networkUnreachable);
    expect(failure.isRetryable, isTrue);
  });

  test('maps unauthorized responses to authUnauthorized', () {
    final failure = mapDioException(
      _exception(DioExceptionType.badResponse, statusCode: 401),
    );

    expect(failure.code, FailureCode.authUnauthorized);
    expect(failure.kind, FailureKind.authorization);
  });

  test('keeps a safe server message from the response body', () {
    final failure = mapDioException(
      _exception(
        DioExceptionType.badResponse,
        statusCode: 401,
        data: <String, Object?>{
          'message': 'You don\'t have any active subscriptions',
        },
      ),
    );

    expect(failure.message, 'You don\'t have any active subscriptions');
    expect(
      failure.details['serverMessage'],
      'You don\'t have any active subscriptions',
    );
    expect(failure.details['statusCode'], 401);
  });

  test('maps 404 to unavailable', () {
    final failure = mapDioException(
      _exception(DioExceptionType.badResponse, statusCode: 404),
    );

    expect(failure.code, FailureCode.unavailable);
    expect(failure.kind, FailureKind.unavailable);
    expect(failure.isRetryable, isFalse);
  });

  test('maps 429 to a retryable failure with retry-after', () {
    final failure = mapDioException(
      _exception(
        DioExceptionType.badResponse,
        statusCode: 429,
        headers: <String, List<String>>{
          'retry-after': <String>['12'],
        },
      ),
    );

    expect(failure.code, FailureCode.networkServer);
    expect(failure.isRetryable, isTrue);
    expect(failure.details['retryAfterSeconds'], 12);
  });

  test('maps other 4xx responses to validation failures', () {
    final failure = mapDioException(
      _exception(
        DioExceptionType.badResponse,
        statusCode: 400,
        data: <String, Object?>{'message': 'identifier is required'},
      ),
    );

    expect(failure.code, FailureCode.validationInvalidInput);
    expect(failure.message, 'identifier is required');
  });

  test('maps server responses to a retryable networkServer failure', () {
    final failure = mapDioException(
      _exception(DioExceptionType.badResponse, statusCode: 503),
    );

    expect(failure.code, FailureCode.networkServer);
    expect(failure.isRetryable, isTrue);
  });

  test('maps cancellation to the cancelled failure', () {
    final failure = mapDioException(_exception(DioExceptionType.cancel));

    expect(failure.code, FailureCode.cancelled);
    expect(failure.isCancelled, isTrue);
  });

  test('keeps an existing Failure from the transport', () {
    const original = Failure(
      code: FailureCode.networkOffline,
      message: 'offline',
    );
    final failure = mapDioException(
      DioException(
        requestOptions: RequestOptions(path: '/'),
        error: original,
      ),
    );

    expect(failure, same(original));
  });
}
