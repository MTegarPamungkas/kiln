import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/rest_auth/auth_middleware.dart';
import 'package:full_stack/extensions/rest_auth/auth_request_policy.dart';

import 'test_support.dart';

final class _TokenProvider implements TokenProvider {
  _TokenProvider(this.token);

  String? token;

  @override
  Future<String?> accessToken({bool forceRefresh = false}) async => token;

  @override
  Future<void> clear() async {
    token = null;
  }
}

AuthMiddleware _middleware(String? token) => AuthMiddleware(
  _TokenProvider(token),
  policy: const AuthRequestPolicy(testConfig),
);

void main() {
  test('adds the bearer token to backend requests', () async {
    late HttpRequest seen;

    await _middleware('abc').handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/me'),
      ),
      (request) async {
        seen = request;
        return const HttpResponse(statusCode: 200);
      },
    );

    expect(seen.headers['Authorization'], 'Bearer abc');
  });

  test('keeps an existing Authorization header', () async {
    late HttpRequest seen;

    await _middleware('abc').handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/me'),
        headers: const <String, String>{'authorization': 'Bearer custom'},
      ),
      (request) async {
        seen = request;
        return const HttpResponse(statusCode: 200);
      },
    );

    expect(seen.headers, <String, String>{'authorization': 'Bearer custom'});
  });

  test('passes through without a token', () async {
    late HttpRequest seen;

    await _middleware(null).handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/me'),
      ),
      (request) async {
        seen = request;
        return const HttpResponse(statusCode: 200);
      },
    );

    expect(seen.headers.containsKey('Authorization'), isFalse);
  });

  test('never sends the bearer token to another origin', () async {
    late HttpRequest seen;

    await _middleware('abc').handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://cdn.third-party.test/file'),
      ),
      (request) async {
        seen = request;
        return const HttpResponse(statusCode: 200);
      },
    );

    expect(seen.headers.containsKey('Authorization'), isFalse);
  });

  test('does not add the bearer token to the credential endpoints', () async {
    for (final path in <String>[
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
    ]) {
      late HttpRequest seen;
      await _middleware('abc').handle(
        HttpRequest(
          method: HttpMethod.post,
          uri: Uri.parse('https://api.kiln.dev$path'),
        ),
        (request) async {
          seen = request;
          return const HttpResponse(statusCode: 200);
        },
      );
      expect(seen.headers.containsKey('Authorization'), isFalse, reason: path);
    }
  });

  test(
    'resolves relative backend requests before checking the origin',
    () async {
      late HttpRequest seen;

      await _middleware('abc').handle(
        HttpRequest(method: HttpMethod.get, uri: Uri.parse('/me')),
        (request) async {
          seen = request;
          return const HttpResponse(statusCode: 200);
        },
      );

      expect(seen.uri, Uri.parse('https://api.kiln.dev/me'));
      expect(seen.headers['Authorization'], 'Bearer abc');
    },
  );
}
