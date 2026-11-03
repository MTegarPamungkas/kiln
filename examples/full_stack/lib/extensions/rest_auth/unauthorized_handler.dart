import 'package:kiln_core/kiln_core.dart';

/// Refreshes once after a 401, retries once, then signs out.
final class UnauthorizedHandler implements HttpMiddleware {
  const UnauthorizedHandler({required this.refresh, required this.signOut});

  final Future<String?> Function() refresh;
  final Future<void> Function() signOut;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    final response = await next(request);
    if (response.statusCode != 401) {
      return response;
    }

    String? token;
    try {
      token = await refresh();
    } on Object {
      token = null;
    }
    if (token == null || token.isEmpty) {
      await signOut();
      return response;
    }

    final retried = await next(
      request.copyWith(
        headers: <String, String>{
          ...request.headers,
          'Authorization': 'Bearer $token',
        },
      ),
    );
    if (retried.statusCode == 401) {
      await signOut();
    }
    return retried;
  }
}
