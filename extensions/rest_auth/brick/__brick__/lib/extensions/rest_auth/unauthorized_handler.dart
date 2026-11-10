import 'package:kiln_core/kiln_core.dart';

import 'auth_request_policy.dart';

/// Refreshes once after a backend 401, retries once, then clears the session.
final class UnauthorizedHandler implements HttpMiddleware {
  const UnauthorizedHandler({
    required this.refresh,
    required this.signOut,
    required this.policy,
  });

  final Future<String?> Function() refresh;
  final Future<void> Function() signOut;
  final AuthRequestPolicy policy;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    request = policy.resolve(request);
    final response = await next(request);
    if (response.statusCode != 401 || !policy.allows(request)) {
      return response;
    }

    request.cancelToken?.throwIfCancelled();
    String? token;
    try {
      token = await refresh();
    } on Failure catch (failure) {
      if (!failure.isAuthFailure) {
        rethrow;
      }
      token = null;
    }
    request.cancelToken?.throwIfCancelled();
    if (token == null || token.isEmpty) {
      await signOut();
      return response;
    }

    final retried = await next(
      request.copyWith(
        headers: <String, String>{
          for (final header in request.headers.entries)
            if (header.key.toLowerCase() != 'authorization') header.key: header.value,
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
