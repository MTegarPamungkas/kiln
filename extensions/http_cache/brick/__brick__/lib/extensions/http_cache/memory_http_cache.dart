import 'package:kiln_core/kiln_core.dart';

import 'cache_settings.dart';
import 'cache_store.dart';

/// [HttpCache] implementation backed by an in-memory store.
final class MemoryHttpCache implements HttpCache {
  MemoryHttpCache({
    this.settings = HttpCacheSettings.defaults,
    this.clock = const SystemClock(),
    CacheStore? store,
  }) : _store = store ?? MemoryCacheStore();

  final HttpCacheSettings settings;
  final Clock clock;
  final CacheStore _store;

  @override
  Future<CacheEntry?> read(String key) => _store.read(key);

  @override
  Future<void> write(
    String key,
    HttpResponse response, {
    Duration? ttl,
    Set<String> tags = const <String>{},
  }) async {
    final all = await _store.readAll();
    if (!all.containsKey(key) && all.length >= settings.maxEntries) {
      final oldest = all.entries.reduce(
        (left, right) => left.value.storedAt.isBefore(right.value.storedAt)
            ? left
            : right,
      );
      await _store.delete(oldest.key);
    }
    await _store.write(
      key,
      CacheEntry(
        response: response,
        storedAt: clock.now().toUtc(),
        ttl: ttl,
        tags: tags,
      ),
    );
  }

  @override
  Future<void> invalidate(String prefix, {String? tag}) async {
    final all = await _store.readAll();
    for (final entry in all.entries) {
      if (entry.key.contains(prefix) ||
          (tag != null && entry.value.tags.contains(tag))) {
        await _store.delete(entry.key);
      }
    }
  }

  @override
  Future<void> clear() => _store.clear();
}
