import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/dio/interceptors/request_id_interceptor.dart';

void main() {
  test('adds X-Request-Id to a request without one', () async {
    HttpRequest? seen;
    final pipeline = HttpPipeline([const RequestIdInterceptor()]);

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

    expect(seen?.headers[RequestIdInterceptor.headerName], isNotEmpty);
  });

  test('keeps an existing request id', () async {
    HttpRequest? seen;
    final pipeline = HttpPipeline([const RequestIdInterceptor()]);

    await pipeline.execute(
      HttpRequest(
        method: HttpMethod.get,
        uri: Uri.parse('https://api.kiln.dev'),
        headers: const {RequestIdInterceptor.headerName: 'existing-id'},
      ),
      (request) async {
        seen = request;
        return const HttpResponse(statusCode: 200);
      },
    );

    expect(seen?.headers[RequestIdInterceptor.headerName], 'existing-id');
  });
}
