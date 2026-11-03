import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/http_cache/cache_interceptor.dart';
import 'package:{{app_name}}/extensions/http_cache/cache_key.dart';
import 'package:{{app_name}}/extensions/http_cache/memory_http_cache.dart';

HttpRequest _get([String path = '/users']) {
  return HttpRequest(
    method: HttpMethod.get,
    uri: Uri.parse('https://api.kiln.dev$path'),
  );
}

HttpResponse _response(String data, {String? cacheControl, String? etag}) {
  return HttpResponse(
    statusCode: 200,
    data: data,
    headers: <String, List<String>>{
      if (cacheControl != null) 'Cache-Control': [cacheControl],
      if (etag != null) 'ETag': [etag],
    },
  );
}

void main() {
  test('serves a fresh entry without calling the network', () async {
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final cache = MemoryHttpCache(clock: clock);
    final interceptor = CacheInterceptor(cache: cache, clock: clock);
    var calls = 0;

    Future<HttpResponse> terminal(HttpRequest request) async {
      calls++;
      return _response('network', cacheControl: 'max-age=60');
    }

    final first = await interceptor.handle(_get(), terminal);
    final second = await interceptor.handle(_get(), terminal);

    expect(first.fromCache, isFalse);
    expect(second.fromCache, isTrue);
    expect(second.data, 'network');
    expect(calls, 1);
  });

  test('revalidates with ETag and uses a 304 response', () async {
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final cache = MemoryHttpCache(clock: clock);
    final interceptor = CacheInterceptor(cache: cache, clock: clock);
    var calls = 0;
    String? ifNoneMatch;

    Future<HttpResponse> terminal(HttpRequest request) async {
      calls++;
      if (calls == 1) {
        return _response('v1', cacheControl: 'max-age=1', etag: 'v1');
      }
      ifNoneMatch = request.headers['If-None-Match'];
      return const HttpResponse(statusCode: 304);
    }

    await interceptor.handle(_get(), terminal);
    clock.advance(const Duration(seconds: 2));
    final second = await interceptor.handle(_get(), terminal);

    expect(ifNoneMatch, 'v1');
    expect(second.fromCache, isTrue);
    expect(second.data, 'v1');
    expect(calls, 2);
  });

  test('invalidates entries after a mutation', () async {
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final cache = MemoryHttpCache(clock: clock);
    final interceptor = CacheInterceptor(cache: cache, clock: clock);
    var calls = 0;

    Future<HttpResponse> terminal(HttpRequest request) async {
      calls++;
      return _response('data', cacheControl: 'max-age=60');
    }

    await interceptor.handle(_get(), terminal);
    await interceptor.handle(
      HttpRequest(
        method: HttpMethod.post,
        uri: Uri.parse('https://api.kiln.dev/users'),
      ),
      (_) async => const HttpResponse(statusCode: 200),
    );
    await interceptor.handle(_get(), terminal);

    expect(calls, 2);
  });

  test('serves stale data while refreshing in the background', () async {
    final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
    final cache = MemoryHttpCache(clock: clock);
    final interceptor = CacheInterceptor(cache: cache, clock: clock);
    var calls = 0;

    Future<HttpResponse> terminal(HttpRequest request) async {
      calls++;
      return _response(
        'data-$calls',
        cacheControl: 'max-age=1, stale-while-revalidate=30',
      );
    }

    await interceptor.handle(_get(), terminal);
    clock.advance(const Duration(seconds: 2));
    final stale = await interceptor.handle(_get(), terminal);

    expect(stale.data, 'data-1');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final refreshed = await cache.read(
      const CacheKeyBuilder().build(_get()),
    );
    expect(refreshed?.response.data, 'data-2');
  });
}
