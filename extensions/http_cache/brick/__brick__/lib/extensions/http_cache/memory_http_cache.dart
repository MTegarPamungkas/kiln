import 'dart:collection';
import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

import 'cache_invalidation.dart';
import 'cache_settings.dart';
import 'cache_store.dart';

/// [HttpCache] implementation backed by an in-memory store with LRU eviction,
/// byte budget enforcement, and defensive payload cloning.
final class MemoryHttpCache implements HttpCache {
  MemoryHttpCache({
    this.settings = HttpCacheSettings.defaults,
    this.clock = const SystemClock(),
    CacheStore? store,
  }) : _store = store ?? MemoryCacheStore();

  final HttpCacheSettings settings;
  final Clock clock;
  final CacheStore _store;

  final LinkedHashMap<String, int> _lruBytes = LinkedHashMap<String, int>();
  final Map<String, Set<String>> _tagIndex = <String, Set<String>>{};
  int _totalBytes = 0;

  @override
  Future<CacheEntry?> read(String key) async {
    final entry = await _store.read(key);
    if (entry == null) {
      _removeMeta(key);
      return null;
    }
    final existingBytes = _lruBytes.remove(key);
    if (existingBytes != null) {
      _lruBytes[key] = existingBytes;
    }
    return _cloneEntry(entry);
  }

  @override
  Future<void> write(
    String key,
    HttpResponse response, {
    Duration? ttl,
    Set<String> tags = const <String>{},
  }) async {
    final clonedResponse = _cloneResponse(response);
    final entryBytes = _estimateBytes(clonedResponse);
    if (entryBytes > settings.maxBytes) {
      return;
    }

    _removeMeta(key);
    while (_lruBytes.isNotEmpty &&
        (_lruBytes.length >= settings.maxEntries ||
            _totalBytes + entryBytes > settings.maxBytes)) {
      final victim = _lruBytes.keys.first;
      _removeMeta(victim);
      await _store.delete(victim);
    }

    final frozenTags = Set<String>.unmodifiable(tags);
    await _store.write(
      key,
      CacheEntry(
        response: clonedResponse,
        storedAt: clock.now().toUtc(),
        ttl: ttl,
        tags: frozenTags,
      ),
    );
    _lruBytes[key] = entryBytes;
    _totalBytes += entryBytes;
    for (final tag in frozenTags) {
      _tagIndex.putIfAbsent(tag, () => <String>{}).add(key);
    }
  }

  @override
  Future<void> invalidate(String prefix, {String? tag}) async {
    final toDelete = <String>{};
    for (final key in _lruBytes.keys) {
      if (CacheInvalidation.matchesPrefix(key, prefix)) {
        toDelete.add(key);
      }
    }
    if (tag != null) {
      final tagged = _tagIndex[tag];
      if (tagged != null) {
        toDelete.addAll(tagged);
      }
    }
    // Also honor entries written directly to an injected CacheStore.
    if (_lruBytes.isEmpty) {
      final all = await _store.readAll();
      for (final entry in all.entries) {
        if (CacheInvalidation.matchesPrefix(entry.key, prefix) ||
            (tag != null && entry.value.tags.contains(tag))) {
          toDelete.add(entry.key);
        }
      }
    }
    for (final key in toDelete) {
      _removeMeta(key);
      await _store.delete(key);
    }
  }

  @override
  Future<void> clear() async {
    _lruBytes.clear();
    _tagIndex.clear();
    _totalBytes = 0;
    await _store.clear();
  }

  void _removeMeta(String key) {
    final bytes = _lruBytes.remove(key);
    if (bytes != null) {
      _totalBytes -= bytes;
      if (_totalBytes < 0) {
        _totalBytes = 0;
      }
    }
    final emptyTags = <String>[];
    for (final entry in _tagIndex.entries) {
      entry.value.remove(key);
      if (entry.value.isEmpty) {
        emptyTags.add(entry.key);
      }
    }
    for (final tag in emptyTags) {
      _tagIndex.remove(tag);
    }
  }

  static CacheEntry _cloneEntry(CacheEntry entry) {
    return CacheEntry(
      response: _cloneResponse(entry.response),
      storedAt: entry.storedAt,
      ttl: entry.ttl,
      tags: entry.tags,
    );
  }

  static HttpResponse _cloneResponse(HttpResponse response) {
    return response.copyWith(
      data: _deepClone(response.data),
      headers: <String, List<String>>{
        for (final header in response.headers.entries)
          header.key: List<String>.of(header.value),
      },
    );
  }

  static Object? _deepClone(Object? value) {
    if (value is Map<String, Object?>) {
      return <String, Object?>{
        for (final entry in value.entries)
          entry.key: _deepClone(entry.value),
      };
    }
    if (value is Map) {
      return <Object?, Object?>{
        for (final entry in value.entries)
          entry.key: _deepClone(entry.value),
      };
    }
    if (value is List) {
      return value.map(_deepClone).toList();
    }
    return value;
  }

  static int _estimateBytes(HttpResponse response) {
    try {
      return utf8.encode(jsonEncode(response.data)).length + 128;
    } on Object {
      return '${response.data}'.length * 2 + 128;
    }
  }
}
