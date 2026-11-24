import 'dart:collection';
import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

import 'cache_invalidation.dart';
import 'cache_settings.dart';

final class _StorageIndexEntry {
  _StorageIndexEntry({
    required this.rawKey,
    required this.storedAt,
    required this.bytes,
    required this.tags,
  });

  final String rawKey;
  final DateTime storedAt;
  final int bytes;
  final Set<String> tags;
}

/// [HttpCache] implementation backed by the [Storage] contract.
///
/// Keeps a lightweight in-memory LRU and tag index so evictions and tag
/// invalidations do not decode every persisted payload on the UI isolate.
final class StorageHttpCache implements HttpCache {
  StorageHttpCache({
    required this.storage,
    this.settings = HttpCacheSettings.defaults,
    this.clock = const SystemClock(),
    this.namespace = 'kiln.http_cache.',
  });

  final Storage storage;
  final HttpCacheSettings settings;
  final Clock clock;
  final String namespace;

  final LinkedHashMap<String, _StorageIndexEntry> _index =
      LinkedHashMap<String, _StorageIndexEntry>();
  final Map<String, Set<String>> _tagIndex = <String, Set<String>>{};
  int _totalBytes = 0;
  bool _indexed = false;
  Future<void>? _indexingFuture;

  String _storageKey(String key) => '$namespace$key';

  @override
  Future<CacheEntry?> read(String key) async {
    await _ensureIndexed();
    final fullKey = _storageKey(key);
    final raw = await storage.read(fullKey);
    if (raw == null) {
      _removeFromIndex(fullKey);
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final response = decoded['response'];
      if (response is! Map) {
        return null;
      }
      final entry = CacheEntry(
        response: HttpResponse(
          statusCode: decoded['status'] as int? ?? 0,
          data: response['data'],
          headers: _headers(response['headers']),
          requestUri: response['uri'] == null
              ? null
              : Uri.tryParse('${response['uri']}'),
          fromCache: response['fromCache'] == true,
        ),
        storedAt:
            DateTime.tryParse('${decoded['storedAt'] ?? ''}')?.toUtc() ??
            clock.now().toUtc(),
        ttl: decoded['ttl'] is int
            ? Duration(milliseconds: decoded['ttl']! as int)
            : null,
        tags: (decoded['tags'] as List<Object?>? ?? const <Object?>[])
            .map((value) => '$value')
            .toSet(),
      );
      _touchIndex(
        fullKey,
        _StorageIndexEntry(
          rawKey: key,
          storedAt: entry.storedAt,
          bytes: utf8.encode(raw).length,
          tags: entry.tags,
        ),
      );
      return entry;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(
    String key,
    HttpResponse response, {
    Duration? ttl,
    Set<String> tags = const <String>{},
  }) async {
    await _ensureIndexed();
    final now = clock.now().toUtc();
    final payload = <String, Object?>{
      'status': response.statusCode,
      'storedAt': now.toIso8601String(),
      'ttl': ttl?.inMilliseconds,
      'tags': tags.toList(growable: false),
      'response': <String, Object?>{
        'data': response.data,
        'headers': response.headers,
        'uri': response.requestUri?.toString(),
        'fromCache': false,
      },
    };
    final String encoded;
    try {
      encoded = jsonEncode(payload);
    } on Object {
      // A non-JSON payload is not cacheable.
      return;
    }
    final byteSize = utf8.encode(encoded).length;
    if (byteSize > settings.maxBytes) {
      return;
    }

    final fullKey = _storageKey(key);
    _removeFromIndex(fullKey);
    await _evictIfNeeded(incomingBytes: byteSize);

    try {
      await storage.write(fullKey, encoded);
      _putIndex(
        fullKey,
        _StorageIndexEntry(
          rawKey: key,
          storedAt: now,
          bytes: byteSize,
          tags: Set<String>.unmodifiable(tags),
        ),
      );
    } on Object {
      // Best-effort cache write.
    }
  }

  @override
  Future<void> invalidate(String prefix, {String? tag}) async {
    await _ensureIndexed();
    final toDelete = <String>{};
    for (final entry in _index.entries) {
      if (CacheInvalidation.matchesPrefix(entry.value.rawKey, prefix)) {
        toDelete.add(entry.key);
      }
    }
    if (tag != null) {
      final tagged = _tagIndex[tag];
      if (tagged != null) {
        toDelete.addAll(tagged);
      }
    }
    for (final fullKey in toDelete) {
      _removeFromIndex(fullKey);
      await storage.delete(fullKey);
    }
  }

  @override
  Future<void> clear() async {
    await _ensureIndexed();
    final keys = _index.keys.toList(growable: false);
    _index.clear();
    _tagIndex.clear();
    _totalBytes = 0;
    for (final key in keys) {
      await storage.delete(key);
    }
  }

  Future<void> _ensureIndexed() {
    if (_indexed) {
      return Future<void>.value();
    }
    return _indexingFuture ??= _buildIndex();
  }

  Future<void> _buildIndex() async {
    final keys = await storage.keys();
    final names = keys.where((key) => key.startsWith(namespace)).toList()
      ..sort();
    final loaded = <MapEntry<String, _StorageIndexEntry>>[];
    for (final fullKey in names) {
      final raw = await storage.read(fullKey);
      if (raw == null) {
        continue;
      }
      final meta = _parseMeta(fullKey, raw);
      if (meta == null) {
        await storage.delete(fullKey);
        continue;
      }
      loaded.add(MapEntry<String, _StorageIndexEntry>(fullKey, meta));
    }
    loaded.sort((a, b) => a.value.storedAt.compareTo(b.value.storedAt));
    for (final item in loaded) {
      _putIndex(item.key, item.value);
    }
    _indexed = true;
    _indexingFuture = null;
  }

  _StorageIndexEntry? _parseMeta(String fullKey, String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final storedAt = DateTime.tryParse('${decoded['storedAt'] ?? ''}')?.toUtc();
      if (storedAt == null) {
        return null;
      }
      final tags = (decoded['tags'] as List<Object?>? ?? const <Object?>[])
          .map((value) => '$value')
          .toSet();
      return _StorageIndexEntry(
        rawKey: fullKey.substring(namespace.length),
        storedAt: storedAt,
        bytes: utf8.encode(raw).length,
        tags: tags,
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> _evictIfNeeded({required int incomingBytes}) async {
    while (_index.isNotEmpty &&
        (_index.length >= settings.maxEntries ||
            _totalBytes + incomingBytes > settings.maxBytes)) {
      final victimKey = _index.keys.first;
      _removeFromIndex(victimKey);
      await storage.delete(victimKey);
    }
  }

  void _touchIndex(String fullKey, _StorageIndexEntry entry) {
    _removeFromIndex(fullKey);
    _putIndex(fullKey, entry);
  }

  void _putIndex(String fullKey, _StorageIndexEntry entry) {
    _index[fullKey] = entry;
    _totalBytes += entry.bytes;
    for (final tag in entry.tags) {
      _tagIndex.putIfAbsent(tag, () => <String>{}).add(fullKey);
    }
  }

  void _removeFromIndex(String fullKey) {
    final removed = _index.remove(fullKey);
    if (removed == null) {
      return;
    }
    _totalBytes -= removed.bytes;
    if (_totalBytes < 0) {
      _totalBytes = 0;
    }
    for (final tag in removed.tags) {
      final bucket = _tagIndex[tag];
      if (bucket != null) {
        bucket.remove(fullKey);
        if (bucket.isEmpty) {
          _tagIndex.remove(tag);
        }
      }
    }
  }

  Map<String, List<String>> _headers(Object? value) {
    if (value is! Map) {
      return const <String, List<String>>{};
    }
    return <String, List<String>>{
      for (final entry in value.entries)
        '${entry.key}': entry.value is Iterable
            ? (entry.value! as Iterable).map((item) => '$item').toList()
            : <String>['${entry.value}'],
    };
  }
}
