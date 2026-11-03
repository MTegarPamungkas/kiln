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
    maxAttempts: {{max_attempts}},
    initialDelay: Duration(milliseconds: {{initial_delay_ms}}),
    maxDelay: Duration(milliseconds: {{max_delay_ms}}),
    jitter: {{jitter}},
  );

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final bool jitter;
  final Set<int> retryableStatusCodes;
}
