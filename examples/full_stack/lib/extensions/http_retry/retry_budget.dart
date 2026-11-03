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
    final attempts = _attempts.putIfAbsent(key, () => <DateTime>[]);
    attempts.removeWhere((time) => time.isBefore(cutoff));
    if (attempts.length >= maxRetries) {
      return false;
    }
    attempts.add(now);
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
    return (maxRetries - attempts.length).clamp(0, maxRetries);
  }
}
