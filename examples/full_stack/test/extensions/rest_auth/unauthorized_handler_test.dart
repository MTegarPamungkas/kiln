import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/rest_auth/unauthorized_handler.dart';

void main() {
  test('refreshes and retries once after a 401', () async {
    var signOuts = 0;
    var calls = 0;
    final handler = UnauthorizedHandler(
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
}
