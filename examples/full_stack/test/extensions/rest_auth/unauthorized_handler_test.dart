import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/rest_auth/auth_request_policy.dart';
import 'package:full_stack/extensions/rest_auth/unauthorized_handler.dart';

import 'test_support.dart';

const _policy = AuthRequestPolicy(testConfig);

void main() {
  test('refreshes and retries once after a backend 401', () async {
    var signOuts = 0;
    var calls = 0;
    final handler = UnauthorizedHandler(
      policy: _policy,
      refresh: () async => 'fresh',
      signOut: () async => signOuts++,
    );
    final seen = <HttpRequest>[];

    final response = await handler.handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/me'),
      ),
      (request) async {
        seen.add(request);
        calls++;
        return HttpResponse(statusCode: calls == 1 ? 401 : 200);
      },
    );

    expect(response.statusCode, 200);
    expect(seen, hasLength(2));
    expect(seen.last.headers['Authorization'], 'Bearer fresh');
    expect(signOuts, 0);
  });

  test('signs out when the refresh fails', () async {
    var signOuts = 0;
    final handler = UnauthorizedHandler(
      policy: _policy,
      refresh: () async => null,
      signOut: () async => signOuts++,
    );

    final response = await handler.handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/me'),
      ),
      (_) async => const HttpResponse(statusCode: 401),
    );

    expect(response.statusCode, 401);
    expect(signOuts, 1);
  });

  test('signs out when the retry is rejected again', () async {
    var signOuts = 0;
    final handler = UnauthorizedHandler(
      policy: _policy,
      refresh: () async => 'fresh',
      signOut: () async => signOuts++,
    );

    await handler.handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/me'),
      ),
      (_) async => const HttpResponse(statusCode: 401),
    );

    expect(signOuts, 1);
  });

  test('leaves non-401 responses alone', () async {
    var signOuts = 0;
    final handler = UnauthorizedHandler(
      policy: _policy,
      refresh: () async => 'fresh',
      signOut: () async => signOuts++,
    );

    final response = await handler.handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev/me'),
      ),
      (_) async => const HttpResponse(statusCode: 500),
    );

    expect(response.statusCode, 500);
    expect(signOuts, 0);
  });

  test('a foreign 401 neither refreshes nor signs the user out', () async {
    var refreshes = 0;
    var signOuts = 0;
    final handler = UnauthorizedHandler(
      policy: _policy,
      refresh: () async {
        refreshes++;
        return 'fresh';
      },
      signOut: () async => signOuts++,
    );

    final response = await handler.handle(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://cdn.third-party.test/private'),
      ),
      (_) async => const HttpResponse(statusCode: 401),
    );

    expect(response.statusCode, 401);
    expect(refreshes, 0);
    expect(signOuts, 0);
  });

  test(
    'a credential endpoint 401 does not start a recursive refresh',
    () async {
      var refreshes = 0;
      final handler = UnauthorizedHandler(
        policy: _policy,
        refresh: () async {
          refreshes++;
          return 'fresh';
        },
        signOut: () async {},
      );

      final response = await handler.handle(
        HttpRequest(
          method: HttpMethod.post,
          uri: Uri.parse('https://api.kiln.dev/auth/refresh'),
        ),
        (_) async => const HttpResponse(statusCode: 401),
      );

      expect(response.statusCode, 401);
      expect(refreshes, 0);
    },
  );
}
