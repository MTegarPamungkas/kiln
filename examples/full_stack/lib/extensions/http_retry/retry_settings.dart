/// Typed retry settings for the application.
final class HttpRetrySettings {
  const HttpRetrySettings({
    required this.maxAttempts,
    this.initialDelay = const Duration(milliseconds: 250),
    this.maxDelay = const Duration(seconds: 8),
    this.jitter = true,
    this.retryableStatusCodes = const <int>{408, 429, 500, 502, 503, 504},
  });

  static const defaults = HttpRetrySettings(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 250),
    maxDelay: Duration(milliseconds: 8000),
    jitter: true,
  );

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final bool jitter;
  final Set<int> retryableStatusCodes;
}
