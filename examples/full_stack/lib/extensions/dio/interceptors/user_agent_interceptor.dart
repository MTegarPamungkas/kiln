import 'package:kiln_core/kiln_core.dart';

/// Adds a User-Agent header identifying the generated application.
class UserAgentInterceptor implements HttpMiddleware {
  const UserAgentInterceptor({this.userAgent = 'Kiln/0.1.0 (Dart)'});

  final String userAgent;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) {
    if (request.headers.containsKey('User-Agent')) {
      return next(request);
    }
    return next(
      request.copyWith(
        headers: <String, String>{
          ...request.headers,
          'User-Agent': userAgent,
        },
      ),
    );
  }
}
