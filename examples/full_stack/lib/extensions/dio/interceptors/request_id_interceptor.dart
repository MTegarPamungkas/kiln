import 'dart:math';

import 'package:kiln_core/kiln_core.dart';

/// Adds a request id used to correlate logs and server traces.
class RequestIdInterceptor implements HttpMiddleware {
  const RequestIdInterceptor();

  static const headerName = 'X-Request-Id';
  static final Random _random = Random();

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) {
    if (request.headers.containsKey(headerName)) {
      return next(request);
    }
    final id =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-'
        '${_random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return next(
      request.copyWith(
        headers: <String, String>{...request.headers, headerName: id},
      ),
    );
  }
}
