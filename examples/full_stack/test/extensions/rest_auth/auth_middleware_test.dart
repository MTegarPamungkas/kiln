import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/rest_auth/auth_middleware.dart';

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

void main() {
  test('adds the bearer token', () async {
    final middleware = AuthMiddleware(_TokenProvider('abc'));
    late HttpRequest seen;

    await middleware.handle(
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
    final middleware = AuthMiddleware(_TokenProvider('abc'));
    late HttpRequest seen;

    await middleware.handle(
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
    final middleware = AuthMiddleware(_TokenProvider(null));
    late HttpRequest seen;

    await middleware.handle(
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
}
