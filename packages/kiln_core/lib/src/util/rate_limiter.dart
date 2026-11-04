import 'dart:async';
import 'dart:math' as math;

import 'clock.dart';

/// A token-bucket limiter that gates how often work is performed.
///
/// Buckets start full and refill at a fixed rate, which lets callers burst up
/// to [capacity] before being throttled. Use it at contract boundaries to
/// rate-limit outbound requests without blocking the caller in [tryAcquire].
final class RateLimiter {
  RateLimiter({
    required int capacity,
    required Duration refillInterval,
    int refillAmount = 1,
    Clock clock = const SystemClock(),
  }) : assert(capacity > 0),
       assert(refillInterval > Duration.zero),
       assert(refillAmount > 0),
       _capacity = capacity,
       _refillInterval = refillInterval,
       _refillAmount = refillAmount,
       _clock = clock,
       _tokens = capacity.toDouble(),
       _lastRefill = clock.now();

  final int _capacity;
  final Duration _refillInterval;
  final int _refillAmount;
  final Clock _clock;

  double _tokens;
  DateTime _lastRefill;

  /// Whole tokens currently available.
  int get available => _refill().floor();

  /// Consumes [permits] when available and never blocks.
  bool tryAcquire([int permits = 1]) {
    if (permits <= 0) {
      return true;
    }
    _refill();
    if (_tokens >= permits) {
      _tokens -= permits;
      return true;
    }
    return false;
  }

  /// Blocks until [permits] are available.
  Future<void> acquire([int permits = 1]) async {
    if (permits <= 0) {
      return;
    }
    while (true) {
      if (tryAcquire(permits)) {
        return;
      }
      final rate = _refillAmount / _refillInterval.inMicroseconds;
      final deficit = permits - _tokens;
      final micros = (deficit / rate).ceil();
      await Future<void>.delayed(Duration(microseconds: micros));
    }
  }

  double _refill() {
    final now = _clock.now();
    final elapsed = now.difference(_lastRefill);
    if (elapsed.isNegative) {
      return _tokens;
    }
    if (elapsed.inMicroseconds > 0) {
      final gained =
          elapsed.inMicroseconds *
          (_refillAmount / _refillInterval.inMicroseconds);
      _tokens = math.min(_tokens + gained, _capacity.toDouble());
      _lastRefill = now;
    }
    return _tokens;
  }
}
