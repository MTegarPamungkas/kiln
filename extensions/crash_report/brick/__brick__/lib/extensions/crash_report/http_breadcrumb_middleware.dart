import 'package:kiln_core/kiln_core.dart';

/// [HttpMiddleware] that records each HTTP exchange as a crash-reporter
/// breadcrumb, without ever touching the request body or headers.
///
/// The breadcrumb carries the method, a sanitized URL (no query string or user
/// info), the status, and the duration. It runs at priority 95 — after retry and
/// cache — so it observes the final outcome of every real network attempt.
final class HttpBreadcrumbMiddleware implements HttpMiddleware {
  HttpBreadcrumbMiddleware({
    required this.reporter,
    this.clock = const SystemClock(),
    this.redactor = const PiiRedactor(),
    this.maxUrlLength = 512,
  });

  static const int priority = 95;

  final CrashReporter reporter;
  final Clock clock;
  final PiiRedactor redactor;
  final int maxUrlLength;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    final started = clock.now();
    final url = _safeUrl(request);
    try {
      final response = await next(request);
      await _crumb(
        request,
        url,
        clock.now().difference(started),
        statusCode: response.statusCode,
      );
      return response;
    } on Object {
      await _crumb(request, url, clock.now().difference(started));
      rethrow;
    }
  }

  Future<void> _crumb(
    HttpRequest request,
    String url,
    Duration elapsed, {
    int? statusCode,
  }) {
    final method = _method(request);
    final data = <String, Object?>{
      'method': method,
      'url': url,
      'duration_ms': elapsed.inMilliseconds,
      if (statusCode != null) 'status': statusCode,
    };
    final message = 'HTTP $method $url${statusCode == null ? ' failed' : ' -> $statusCode'}';
    return reporter.addBreadcrumb(message, data: redactor.redactMap(data));
  }

  String _method(HttpRequest request) => request.method.name.toUpperCase();

  String _safeUrl(HttpRequest request) {
    final sanitized = request.resolvedUri
        .replace(userInfo: '', query: '')
        .toString();
    final redacted = redactor.redactText(sanitized);
    if (redacted.length <= maxUrlLength) {
      return redacted;
    }
    return '${redacted.substring(0, maxUrlLength)}...';
  }
}
