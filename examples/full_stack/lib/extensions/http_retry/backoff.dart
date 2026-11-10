import 'dart:math';

import 'retry_settings.dart';

/// Exponential backoff with an optional jitter factor.
final class Backoff {
  Backoff({this.settings = HttpRetrySettings.defaults, Random? random})
    : _random = random ?? Random();

  final HttpRetrySettings settings;
  final Random _random;

  Duration delayFor(int attempt) {
    final safeAttempt = attempt < 1 ? 1 : attempt;
    final exponent = pow(2, safeAttempt - 1).toInt();
    var millis = settings.initialDelay.inMilliseconds * exponent;
    if (millis > settings.maxDelay.inMilliseconds) {
      millis = settings.maxDelay.inMilliseconds;
    }
    if (settings.jitter) {
      final factor = 0.8 + _random.nextDouble() * 0.4;
      millis = (millis * factor).round();
    }
    return Duration(milliseconds: millis);
  }
}
