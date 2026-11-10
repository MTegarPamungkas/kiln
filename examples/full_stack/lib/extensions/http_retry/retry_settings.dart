import 'package:kiln_core/kiln_core.dart';

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

  /// Returns null when valid, or a configuration [Failure] otherwise.
  Failure? validate() {
    if (maxAttempts < 1) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'Retry maxAttempts must be at least one.',
        kind: FailureKind.configuration,
      );
    }
    if (initialDelay.isNegative || maxDelay.isNegative) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'Retry delays cannot be negative.',
        kind: FailureKind.configuration,
      );
    }
    if (maxDelay < initialDelay) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message:
            'Retry maxDelay must be greater than or equal to initialDelay.',
        kind: FailureKind.configuration,
      );
    }
    return null;
  }
}
