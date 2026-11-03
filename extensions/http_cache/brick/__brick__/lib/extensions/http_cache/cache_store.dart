import 'package:kiln_core/kiln_core.dart';

/// Storage backend for cache entries.
abstract interface class CacheStore {
  Future<CacheEntry?> read(String key);

  Future<void> write(String key, CacheEntry entry);

  Future<void> delete(String key);

  Future<void> clear();

  Future<Map<String, CacheEntry>> readAll();
}

/// Cache store kept in process memory.
final class MemoryCacheStore implements CacheStore {
  final Map<String, CacheEntry> _entries = <String, CacheEntry>{};

  @override
  Future<CacheEntry?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, CacheEntry entry) async {
    _entries[key] = entry;
  }

  @override
  Future<void> delete(String key) async {
    _entries.remove(key);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }

  @override
  Future<Map<String, CacheEntry>> readAll() async =>
      Map<String, CacheEntry>.unmodifiable(_entries);
}
