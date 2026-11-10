import 'package:kiln_core/kiln_core.dart';

import 'auth_request_policy.dart';

/// Adds bearer tokens only to eligible backend requests.
final class AuthMiddleware implements HttpMiddleware {
  const AuthMiddleware(this.tokens, {required this.policy});

  final TokenProvider tokens;
  final AuthRequestPolicy policy;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    request = policy.resolve(request);
    if (!policy.allows(request)) {
      return next(request);
    }
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
