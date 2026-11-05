import 'package:kiln_core/kiln_core.dart';

/// Ignores the same link while it stays inside the deduplication window.
final class LinkDeduplicator {
  LinkDeduplicator({
    required this.clock,
    this.window = const Duration(seconds: 2),
  });

  final Clock clock;
  final Duration window;
  final Map<String, DateTime> _seen = <String, DateTime>{};

  /// Returns `true` when [link] was accepted less than [window] ago.
  bool isDuplicate(Uri link) {
    final now = clock.now();
    _prune(now);
    final key = link.toString();
    final seenAt = _seen[key];
    if (seenAt != null && !now.isAfter(seenAt.add(window))) {
      return true;
    }
    _seen[key] = now;
    return false;
  }

  /// Forgets every recorded link.
  void clear() => _seen.clear();

  void _prune(DateTime now) {
    _seen.removeWhere((key, seenAt) => now.isAfter(seenAt.add(window)));
  }
}
