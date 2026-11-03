import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/rest_auth/rest_auth_failure_mapper.dart';

void main() {
  test('maps status codes and server messages', () {
    final invalid = mapRestResponse(
      const HttpResponse(
        statusCode: 400,
        data: <String, Object?>{'message': 'Email tidak valid'},
      ),
    );
    final expired = mapRestResponse(const HttpResponse(statusCode: 401));
    final forbidden = mapRestResponse(const HttpResponse(statusCode: 403));
    final busy = mapRestResponse(const HttpResponse(statusCode: 429));

    expect(invalid.code, FailureCode.validationInvalidInput);
    expect(invalid.message, 'Email tidak valid');
    expect(expired.code, FailureCode.authSessionExpired);
    expect(forbidden.kind, FailureKind.authorization);
    expect(busy.isRetryable, isTrue);
  });

  test('treats 401 as invalid credentials on login', () {
    final failure = mapCredentialResponse(const HttpResponse(statusCode: 401));

    expect(failure.code, FailureCode.authInvalidCredentials);
    expect(failure.kind, FailureKind.authentication);
  });

  test('maps server errors to retryable network failures', () {
    final failure = mapRestResponse(const HttpResponse(statusCode: 503));

    expect(failure.code, FailureCode.networkServer);
    expect(failure.isRetryable, isTrue);
  });
}
