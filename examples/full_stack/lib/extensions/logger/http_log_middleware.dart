import 'package:kiln_core/kiln_core.dart';

/// Logs one line per HTTP exchange without ever touching the body.
///
/// The URL is logged without user info or query parameters, request headers are
/// redacted with [PiiRedactor], and the duration is measured with an injectable
/// [Clock]. Failures are logged at error level and rethrown unchanged.
final class HttpLogMiddleware implements HttpMiddleware {
  HttpLogMiddleware({
    required this.logger,
    this.clock = const SystemClock(),
    this.redactor = const PiiRedactor(),
    this.maxUrlLength = 512,
  });

  /// Runs late in the pipeline so it observes the final status and duration.
  static const int priority = 90;

  final AppLogger logger;
  final Clock clock;
  final PiiRedactor redactor;
  final int maxUrlLength;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    final started = clock.now();
    final url = _safeUrl(request);
    try {
      final response = await next(request);
      final elapsed = clock.now().difference(started);
      final data = _context(
        request: request,
        url: url,
        elapsed: elapsed,
        statusCode: response.statusCode,
      );
      final message =
          'HTTP ${_method(request)} $url -> ${response.statusCode} '
          '(${elapsed.inMilliseconds} ms)';
      final status = response.statusCode;
      if (status >= 500) {
        logger.error(message, data: data);
      } else if (status >= 400) {
        logger.warning(message, data: data);
      } else {
        logger.info(message, data: data);
      }
      return response;
    } on Object catch (error, stackTrace) {
      final elapsed = clock.now().difference(started);
      logger.error(
        'HTTP ${_method(request)} $url failed '
        '(${elapsed.inMilliseconds} ms)',
        error: error,
        stackTrace: stackTrace,
        data: _context(request: request, url: url, elapsed: elapsed),
      );
      rethrow;
    }
  }

  Map<String, Object?> _context({
    required HttpRequest request,
    required String url,
    required Duration elapsed,
    int? statusCode,
  }) {
    return <String, Object?>{
      'method': _method(request),
      'url': url,
      'status': ?statusCode,
      'duration_ms': elapsed.inMilliseconds,
      'headers': redactor.redactHeaders(request.headers),
    };
  }

  String _method(HttpRequest request) => request.method.name.toUpperCase();

  String _safeUrl(HttpRequest request) {
    final resolved = request.resolvedUri;
    final sanitized = resolved.replace(userInfo: '', query: '').toString();
    final redacted = redactor.redactText(sanitized);
    if (redacted.length <= maxUrlLength) {
      return redacted;
    }
    return '${redacted.substring(0, maxUrlLength)}...';
  }
}
