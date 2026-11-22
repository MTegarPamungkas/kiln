import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_cache/cache_settings.dart';
import 'package:{{app_name}}/extensions/http_cache/storage_http_cache.dart';

final class _MemoryStorage implements Storage {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<Set<String>> keys() async => values.keys.toSet();

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  test('evicts the oldest entry when the cache is full', () async {
    final storage = _MemoryStorage();
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final cache = StorageHttpCache(
      storage: storage,
      clock: clock,
      settings: const HttpCacheSettings(maxEntries: 2),
    );

    await cache.write('first', const HttpResponse(statusCode: 200, data: 'a'));
    clock.advance(const Duration(minutes: 1));
    await cache.write('second', const HttpResponse(statusCode: 200, data: 'b'));
    clock.advance(const Duration(minutes: 1));
    await cache.write('third', const HttpResponse(statusCode: 200, data: 'c'));

    expect(await cache.read('first'), isNull);
    expect((await cache.read('second'))?.response.data, 'b');
    expect((await cache.read('third'))?.response.data, 'c');
  });

  test('round-trips a response through Storage', () async {
    final storage = _MemoryStorage();
    final cache = StorageHttpCache(storage: storage);

    await cache.write(
      'get|https://api.kiln.dev/users',
      const HttpResponse(
        statusCode: 200,
        data: {'ok': true},
        headers: {
          'content-type': ['application/json'],
        },
      ),
      ttl: const Duration(seconds: 30),
      tags: const {'users'},
    );

    final entry = await cache.read('get|https://api.kiln.dev/users');
    expect(entry?.response.statusCode, 200);
    expect(entry?.response.data, {'ok': true});
    expect(entry?.ttl, const Duration(seconds: 30));
    expect(entry?.tags, contains('users'));

    await storage.write('user.key', 'keep');
    await cache.clear();
    expect(await cache.read('get|https://api.kiln.dev/users'), isNull);
    expect(storage.values['user.key'], 'keep');
  });

  test('invalidates by prefix', () async {
    final cache = StorageHttpCache(storage: _MemoryStorage());
    await cache.write(
      'get|https://api.kiln.dev/users',
      const HttpResponse(statusCode: 200),
    );
    await cache.write(
      'get|https://api.kiln.dev/posts',
      const HttpResponse(statusCode: 200),
    );

    await cache.invalidate('/users');
    expect(await cache.read('get|https://api.kiln.dev/users'), isNull);
    expect(await cache.read('get|https://api.kiln.dev/posts'), isNotNull);
  });

  test('invalidates by tag without matching response data', () async {
    final storage = _MemoryStorage();
    final cache = StorageHttpCache(storage: storage);
    await cache.write(
      'get|https://api.kiln.dev/a',
      const HttpResponse(statusCode: 200, data: {'role': 'users'}),
      tags: const {'posts'},
    );
    await cache.write(
      'get|https://api.kiln.dev/b',
      const HttpResponse(statusCode: 200),
      tags: const {'users'},
    );

    await cache.invalidate('/nonexistent', tag: 'users');

    expect(await cache.read('get|https://api.kiln.dev/a'), isNotNull);
    expect(await cache.read('get|https://api.kiln.dev/b'), isNull);
  });
}
