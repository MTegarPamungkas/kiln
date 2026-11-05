import 'package:kiln_core/kiln_core.dart';

/// Adds the bearer token to requests that do not set Authorization.
final class AuthMiddleware implements HttpMiddleware {
  const AuthMiddleware(this.tokens);

  final TokenProvider tokens;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    final hasAuthorization = request.headers.keys.any(
      (key) => key.toLowerCase() == 'authorization',
    );
    if (hasAuthorization) {
      return next(request);
    }
    final token = await tokens.accessToken();
    if (token == null || token.isEmpty) {
      return next(request);
    }
    return next(
      request.copyWith(
        headers: <String, String>{
          ...request.headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}
