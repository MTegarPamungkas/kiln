import 'package:kiln_core/kiln_core.dart';

import 'cache_control_parser.dart';

/// Decides whether a stale entry may be served while refreshing.
final class StaleWhileRevalidate {
  const StaleWhileRevalidate();

  bool canServe({
    required CacheEntry entry,
    required CacheControl control,
    required Clock clock,
    required bool enabled,
  }) {
    if (!enabled || control.staleWhileRevalidate == null) {
      return false;
    }
    final now = clock.now().toUtc();
    if (entry.isFresh(now)) {
      return false;
    }
    final ttl = entry.ttl;
    if (ttl == null) {
      return false;
    }
    final age = now.difference(entry.storedAt);
    return age <= ttl + control.staleWhileRevalidate!;
  }
}
