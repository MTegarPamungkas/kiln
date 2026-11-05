import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_auth_gateway.dart';

BetterAuthGateway gatewayReturning(int status, String body) {
  return BetterAuthGateway(
    authUrl: 'https://auth.test/db/auth',
    client: MockClient((request) async {
      return http.Response(
        body,
        status,
        headers: <String, String>{'content-type': 'application/json'},
      );
    }),
  );
}

void main() {
  test('sign-in adopts the returned session', () async {
    late http.Request seen;
    final gateway = BetterAuthGateway(
      authUrl: 'https://auth.test/db/auth',
      client: MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode(<String, Object?>{
            'token': 'sess-1',
            'user': <String, Object?>{
              'id': 'user-1',
              'email': 'user@kiln.dev',
              'name': 'Demo User',
            },
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final session = await gateway.signIn(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    expect(seen.url.path, '/db/auth/sign-in/email');
    expect(session.userId, 'user-1');
    expect(session.email, 'user@kiln.dev');
    expect(session.displayName, 'Demo User');
    expect(session.sessionToken, 'sess-1');
    expect(await gateway.currentSession(), same(session));
  });

  test('bad credentials stay auth.invalid_credentials', () async {
    final gateway = gatewayReturning(
      401,
      jsonEncode(<String, Object?>{
        'code': 'INVALID_EMAIL_OR_PASSWORD',
        'message': 'Invalid email or password',
      }),
    );

    await expectLater(
      gateway.signIn(email: 'user@kiln.dev', password: 'wrong'),
      throwsA(
        isA<Failure>()
            .having((f) => f.code, 'code', FailureCode.authInvalidCredentials)
            .having((f) => f.kind, 'kind', FailureKind.authentication)
            .having((f) => f.message, 'message', 'Invalid email or password')
            .having(
              (f) => f.details,
              'details',
              containsPair('better_auth_code', 'INVALID_EMAIL_OR_PASSWORD'),
            ),
      ),
    );
  });

  test('a non-JSON 401 body still maps to invalid credentials', () async {
    final gateway = gatewayReturning(401, '<html>gateway error</html>');

    await expectLater(
      gateway.signIn(email: 'user@kiln.dev', password: 'wrong'),
      throwsA(
        isA<Failure>()
            .having((f) => f.code, 'code', FailureCode.authInvalidCredentials)
            .having((f) => f.message, 'message', 'Invalid email or password.'),
      ),
    );
  });

  test('a server error is retryable and not invalid_credentials', () async {
    final gateway = gatewayReturning(503, 'upstream unavailable');

    await expectLater(
      gateway.signIn(email: 'user@kiln.dev', password: 'password123'),
      throwsA(
        isA<Failure>()
            .having((f) => f.code, 'code', FailureCode.networkServer)
            .having((f) => f.kind, 'kind', FailureKind.network)
            .having((f) => f.isRetryable, 'isRetryable', isTrue)
            .having(
              (f) => f.message,
              'message',
              isNot(contains('Invalid email or password')),
            ),
      ),
    );
  });

  test('a rate-limited sign-in is retryable and unavailable', () async {
    final gateway = gatewayReturning(429, 'slow down');

    await expectLater(
      gateway.signIn(email: 'user@kiln.dev', password: 'password123'),
      throwsA(
        isA<Failure>()
            .having((f) => f.code, 'code', FailureCode.unavailable)
            .having((f) => f.isRetryable, 'isRetryable', isTrue),
      ),
    );
  });

  test('sign-up with a taken email is a validation failure', () async {
    final gateway = gatewayReturning(
      422,
      jsonEncode(<String, Object?>{
        'code': 'USER_ALREADY_EXISTS',
        'message': 'User already exists',
      }),
    );

    await expectLater(
      gateway.signUp(email: 'user@kiln.dev', password: 'password123'),
      throwsA(
        isA<Failure>()
            .having((f) => f.code, 'code', FailureCode.validationInvalidInput)
            .having((f) => f.kind, 'kind', FailureKind.validation)
            .having(
              (f) => f.message,
              'message',
              'An account with this email already exists.',
            )
            .having(
              (f) => f.details,
              'details',
              containsPair('better_auth_code', 'USER_ALREADY_EXISTS'),
            ),
      ),
    );
  });

  test('sign-up input problems keep the server message', () async {
    final gateway = gatewayReturning(
      400,
      jsonEncode(<String, Object?>{
        'code': 'PASSWORD_TOO_SHORT',
        'message': 'Password too short',
      }),
    );

    await expectLater(
      gateway.signUp(email: 'user@kiln.dev', password: 'x'),
      throwsA(
        isA<Failure>()
            .having((f) => f.code, 'code', FailureCode.validationInvalidInput)
            .having((f) => f.message, 'message', 'Password too short'),
      ),
    );
  });
}
