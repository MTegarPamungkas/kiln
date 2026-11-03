import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/dio/interceptors/user_agent_interceptor.dart';

void main() {
  test('adds the configured User-Agent', () async {
    HttpRequest? seen;
    final pipeline = HttpPipeline([
      const UserAgentInterceptor(userAgent: 'Kiln Test'),
    ]);

    await pipeline.execute(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev'),
      ),
      (request) async {
        seen = request;
        return const HttpResponse(statusCode: 200);
      },
    );

    expect(seen?.headers['User-Agent'], 'Kiln Test');
  });

  test('keeps an existing User-Agent', () async {
    HttpRequest? seen;
    final pipeline = HttpPipeline([const UserAgentInterceptor()]);

    await pipeline.execute(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev'),
        headers: const {'User-Agent': 'Custom/1.0'},
      ),
      (request) async {
        seen = request;
        return const HttpResponse(statusCode: 200);
      },
    );

    expect(seen?.headers['User-Agent'], 'Custom/1.0');
  });
}
