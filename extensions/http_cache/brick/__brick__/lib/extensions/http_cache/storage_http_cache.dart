import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

import 'cache_settings.dart';

/// [HttpCache] implementation backed by the [Storage] contract.
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

  String _key(String key) => '$namespace$key';

  @override
  Future<CacheEntry?> read(String key) async {
    final raw = await storage.read(_key(key));
    if (raw == null) {
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
      return CacheEntry(
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
    final all = await _keys();
    if (!all.contains(_key(key)) && all.length >= settings.maxEntries) {
      await _evictOldest(all);
    }
    final payload = <String, Object?>{
      'status': response.statusCode,
      'storedAt': clock.now().toUtc().toIso8601String(),
      'ttl': ttl?.inMilliseconds,
      'tags': tags.toList(growable: false),
      'response': <String, Object?>{
        'data': response.data,
        'headers': response.headers,
        'uri': response.requestUri?.toString(),
        'fromCache': false,
      },
    };
    try {
      await storage.write(_key(key), jsonEncode(payload));
    } on Object {
      // A non-JSON payload is not cacheable.
    }
  }

  @override
  Future<void> invalidate(String prefix, {String? tag}) async {
    for (final key in await _keys()) {
      if (key.contains(prefix)) {
        await storage.delete(key);
        continue;
      }
      if (tag != null && await _hasTag(key, tag)) {
        await storage.delete(key);
      }
    }
  }

  /// Evicts the entry with the oldest `storedAt`; a key whose payload cannot
  /// be read is removed first.
  Future<void> _evictOldest(List<String> keys) async {
    if (keys.isEmpty) {
      return;
    }
    String? oldestKey;
    DateTime? oldestAt;
    for (final key in keys) {
      final raw = await storage.read(key);
      if (raw == null) {
        continue;
      }
      final storedAt = _storedAt(raw);
      if (storedAt == null) {
        await storage.delete(key);
        return;
      }
      if (oldestAt == null || storedAt.isBefore(oldestAt)) {
        oldestAt = storedAt;
        oldestKey = key;
      }
    }
    if (oldestKey != null) {
      await storage.delete(oldestKey);
    }
  }

  DateTime? _storedAt(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return DateTime.tryParse('${decoded['storedAt'] ?? ''}');
      }
    } on FormatException {
      // A payload the cache cannot read is not a usable entry.
    }
    return null;
  }

  Future<bool> _hasTag(String key, String tag) async {
    final raw = await storage.read(key);
    if (raw == null) {
      return false;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return false;
      }
      final tags = decoded['tags'];
      return tags is List && tags.any((value) => '$value' == tag);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clear() async {
    for (final key in await _keys()) {
      await storage.delete(key);
    }
  }

  Future<List<String>> _keys() async {
    final keys = await storage.keys();
    final names = keys.where((key) => key.startsWith(namespace)).toList()
      ..sort();
    return names;
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
