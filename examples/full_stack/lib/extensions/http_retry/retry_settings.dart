import 'package:kiln_core/kiln_core.dart';

/// Typed retry settings for the application.
final class HttpRetrySettings {
  const HttpRetrySettings({
    required this.maxAttempts,
    this.initialDelay = const Duration(milliseconds: 250),
    this.maxDelay = const Duration(seconds: 8),
    this.jitter = true,
    this.totalBudget,
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

  /// Wall-clock ceiling for one request's whole retry sequence, including the
  /// waits. Null leaves the sequence bounded only by [maxAttempts] and
  /// [maxDelay]. A wait is clipped to the remaining budget, and no attempt is
  /// started once the budget is spent.
  final Duration? totalBudget;
  final Set<int> retryableStatusCodes;

  HttpRetrySettings copyWith({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    bool? jitter,
    Duration? totalBudget,
    Set<int>? retryableStatusCodes,
  }) {
    return HttpRetrySettings(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      initialDelay: initialDelay ?? this.initialDelay,
      maxDelay: maxDelay ?? this.maxDelay,
      jitter: jitter ?? this.jitter,
      totalBudget: totalBudget ?? this.totalBudget,
      retryableStatusCodes: retryableStatusCodes ?? this.retryableStatusCodes,
    );
  }

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
    if (totalBudget != null && totalBudget!.isNegative) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'Retry totalBudget cannot be negative.',
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
