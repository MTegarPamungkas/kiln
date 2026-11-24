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

  test('prefix invalidation respects path segment boundaries', () async {
    final cache = MemoryHttpCache();
    await cache.write(
      'get|https://api.kiln.dev/users/4',
      const HttpResponse(statusCode: 200, data: 'u4'),
      ttl: const Duration(minutes: 1),
    );
    await cache.write(
      'get|https://api.kiln.dev/users/42',
      const HttpResponse(statusCode: 200, data: 'u42'),
      ttl: const Duration(minutes: 1),
    );

    await cache.invalidate('/users/4');
    expect(await cache.read('get|https://api.kiln.dev/users/4'), isNull);
    expect(await cache.read('get|https://api.kiln.dev/users/42'), isNotNull);
  });

  test('defensively clones cached data so callers cannot mutate cache', () async {
    final cache = MemoryHttpCache();
    final payload = <String, Object?>{'name': 'alice'};
    await cache.write(
      'get|https://api.kiln.dev/profile',
      HttpResponse(statusCode: 200, data: payload),
      ttl: const Duration(minutes: 1),
    );
    payload['name'] = 'mutated-after-write';

    final first = await cache.read('get|https://api.kiln.dev/profile');
    final map = first!.response.data! as Map<String, Object?>;
    expect(map['name'], 'alice');
    map['name'] = 'mutated-after-read';

    final second = await cache.read('get|https://api.kiln.dev/profile');
    expect((second!.response.data! as Map<String, Object?>)['name'], 'alice');
  });
}
