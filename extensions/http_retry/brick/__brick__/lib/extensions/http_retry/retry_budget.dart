import 'package:kiln_core/kiln_core.dart';

/// Limits retries per key in a rolling window.
final class RetryBudget {
  RetryBudget({
    this.maxRetries = 10,
    this.window = const Duration(minutes: 1),
    Clock? clock,
  }) : _clock = clock ?? const SystemClock();

  final int maxRetries;
  final Duration window;
  final Clock _clock;
  final Map<String, List<DateTime>> _attempts = <String, List<DateTime>>{};

  bool tryConsume(String key) {
    final now = _clock.now().toUtc();
    final cutoff = now.subtract(window);
    _pruneStale(cutoff);
    final attempts = _attempts[key];
    if (attempts != null) {
      attempts.removeWhere((time) => time.isBefore(cutoff));
      if (attempts.length >= maxRetries) {
        return false;
      }
      attempts.add(now);
      return true;
    }
    if (maxRetries <= 0) {
      return false;
    }
    _attempts[key] = <DateTime>[now];
    return true;
  }

  int remaining(String key) {
    final now = _clock.now().toUtc();
    final cutoff = now.subtract(window);
    final attempts = _attempts[key];
    if (attempts == null) {
      return maxRetries;
    }
    attempts.removeWhere((time) => time.isBefore(cutoff));
    if (attempts.isEmpty) {
      _attempts.remove(key);
      return maxRetries;
    }
    return (maxRetries - attempts.length).clamp(0, maxRetries);
  }

  void _pruneStale(DateTime cutoff) {
    if (_attempts.length <= 16) {
      return;
    }
    final emptyKeys = <String>[];
    _attempts.forEach((key, attempts) {
      attempts.removeWhere((time) => time.isBefore(cutoff));
      if (attempts.isEmpty) {
        emptyKeys.add(key);
      }
    });
    for (final key in emptyKeys) {
      _attempts.remove(key);
    }
  }
}
