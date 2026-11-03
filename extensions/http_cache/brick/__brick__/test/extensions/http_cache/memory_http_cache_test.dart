import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_cache/cache_settings.dart';
import 'package:{{app_name}}/extensions/http_cache/memory_http_cache.dart';

void main() {
  test('stores, reads, expires, and clears entries', () async {
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final cache = MemoryHttpCache(
      settings: const HttpCacheSettings(
        defaultTtl: Duration(seconds: 10),
        maxEntries: 2,
      ),
      clock: clock,
    );

    await cache.write(
      'a',
      const HttpResponse(statusCode: 200, data: 'A'),
      ttl: const Duration(seconds: 10),
      tags: const {'users'},
    );
    final entry = await cache.read('a');

    expect(entry?.response.data, 'A');
    expect(entry?.isFresh(clock.now()), isTrue);

    clock.advance(const Duration(seconds: 11));
    expect(entry?.isFresh(clock.now()), isFalse);

    await cache.write(
      'b',
      const HttpResponse(statusCode: 200, data: 'B'),
      ttl: const Duration(seconds: 10),
    );
    await cache.write(
      'c',
      const HttpResponse(statusCode: 200, data: 'C'),
      ttl: const Duration(seconds: 10),
    );

    expect(await cache.read('a'), isNull);
    expect(await cache.read('b'), isNotNull);
    expect(await cache.read('c'), isNotNull);

    await cache.clear();
    expect(await cache.read('b'), isNull);
  });

  test('invalidates by prefix and tag', () async {
    final cache = MemoryHttpCache();
    await cache.write(
      'get|https://api.kiln.dev/users',
      const HttpResponse(statusCode: 200),
      tags: const {'users'},
    );
    await cache.write(
      'get|https://api.kiln.dev/posts',
      const HttpResponse(statusCode: 200),
      tags: const {'posts'},
    );

    await cache.invalidate('/users');
    expect(await cache.read('get|https://api.kiln.dev/users'), isNull);
    expect(await cache.read('get|https://api.kiln.dev/posts'), isNotNull);

    await cache.invalidate('', tag: 'posts');
    expect(await cache.read('get|https://api.kiln.dev/posts'), isNull);
  });
}
