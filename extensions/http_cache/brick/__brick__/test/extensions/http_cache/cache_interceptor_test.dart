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

const _offline = Failure(
  code: FailureCode.networkOffline, message: 'offline', kind: FailureKind.network,
);

final class _Harness {
  _Harness() {
    cache = MemoryHttpCache(clock: clock);
    interceptor = CacheInterceptor(cache: cache, clock: clock);
  }
  final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
  late final MemoryHttpCache cache;
  late final CacheInterceptor interceptor;

  Future<void> seed(String control) async {
    await interceptor.handle(_get(), (_) async =>
        _response('cached', cacheControl: control, etag: 'v1'));
  }
}

void main() {
  for (final header in ['Authorization', 'cOoKiE']) {
    test('$header bypasses cache when users switch or sign in', () async {
      final harness = _Harness();
      var calls = 0;
      Future<HttpResponse> network(HttpRequest request) async {
        calls++;
        return _response(request.headers[header] ?? 'anonymous', cacheControl: 'max-age=60');
      }
      final anonymous = await harness.interceptor.handle(_get(), network);
      final a = await harness.interceptor.handle(_get().copyWith(headers: {header: 'user-a'}), network);
      final b = await harness.interceptor.handle(_get().copyWith(headers: {header: 'user-b'}), network);
      final signedOut = await harness.interceptor.handle(_get(), network);
      expect(a.data, 'user-a');
      expect(b.data, 'user-b');
      expect(a.fromCache, isFalse);
      expect(b.fromCache, isFalse);
      expect(signedOut.data, anonymous.data);
      expect(calls, 3);
    });

    test('$header responses never populate an empty shared cache', () async {
      final harness = _Harness();
      await harness.interceptor.handle(_get().copyWith(headers: {header: 'secret'}),
          (_) async => _response('private', cacheControl: 'public, max-age=60'));
      expect(await harness.cache.read(const CacheKeyBuilder().build(_get())), isNull);
    });
  }

  for (final headers in <Map<String, List<String>>>[
    {'Cache-Control': ['private, max-age=60']},
    {'Cache-Control': ['max-age=60', 'private="X-User"']},
    {'Cache-Control': ['no-store']},
    {'Set-Cookie': ['session=secret']},
    {'WWW-Authenticate': ['Bearer']},
    {'Vary': ['*']},
    {'Vary': ['Accept-Language']},
    {'Vary': ['Accept', 'X-Tenant']},
    {'Vary': ['Accept'], 'vary': ['Cookie']},
  ]) {
    test('does not store sensitive or unkeyed response: $headers', () async {
      final harness = _Harness();
      var calls = 0;
      Future<HttpResponse> network(HttpRequest _) async {
        calls++;
        return HttpResponse(statusCode: 200, data: 'body', headers: headers);
      }
      await harness.interceptor.handle(_get(), network);
      await harness.interceptor.handle(_get(), network);
      expect(calls, 2);
    });
  }

  test('caches keyed Vary variants and normalizes custom key headers', () async {
    final harness = _Harness();
    final interceptor = CacheInterceptor(cache: harness.cache, clock: harness.clock,
        keyBuilder: const CacheKeyBuilder(varyHeaders: {'Accept-Language'}));
    var calls = 0;
    Future<HttpResponse> network(HttpRequest request) async {
      calls++;
      return HttpResponse(statusCode: 200, data: request.headers['Accept-Language'],
          headers: {'Vary': ['aCcEpT-LaNgUaGe'], 'Cache-Control': ['max-age=60']});
    }
    for (final language in ['en', 'fr', 'en']) {
      final response = await interceptor.handle(_get().copyWith(headers: {'Accept-Language': language}), network);
      expect(response.data, language);
    }
    expect(calls, 2);
  });

  test('request no-store bypasses reads and writes', () async {
    final harness = _Harness();
    await harness.seed('max-age=60');
    final request = _get().copyWith(headers: {'cAcHe-CoNtRoL': 'no-store'});
    final response = await harness.interceptor.handle(request,
        (_) async => _response('uncached', cacheControl: 'max-age=60'));
    expect(response.data, 'uncached');
    expect(response.fromCache, isFalse);
    expect((await harness.cache.read(const CacheKeyBuilder().build(_get())))?.response.data, 'cached');
  });

  test('request no-cache revalidates even fresh data and refuses stale', () async {
    final harness = _Harness();
    await harness.seed('max-age=60, stale-if-error=120, stale-while-revalidate=120');
    final request = _get().copyWith(headers: {'Cache-Control': 'no-cache'});
    final response = await harness.interceptor.handle(request, (outgoing) async {
      expect(outgoing.headers['If-None-Match'], 'v1');
      return const HttpResponse(statusCode: 304);
    });
    expect(response.data, 'cached');
    harness.clock.advance(const Duration(seconds: 61));
    await expectLater(harness.interceptor.handle(request, (_) async => throw _offline), throwsA(_offline));
  });

  for (final control in [
    'max-age=1',
    'max-age=1, no-cache, stale-if-error=60, stale-while-revalidate=60',
    'max-age=1, must-revalidate, stale-if-error=60, stale-while-revalidate=60',
    'max-age=1, stale-if-error=0',
  ]) {
    test('never falls back without explicit permission: $control', () async {
      final harness = _Harness();
      await harness.seed(control);
      harness.clock.advance(const Duration(seconds: 2));
      await expectLater(harness.interceptor.handle(_get(), (_) async => throw _offline), throwsA(_offline));
    });
  }

  test('stale-if-error permits only the explicit bounded window', () async {
    final harness = _Harness();
    await harness.seed('max-age=1, stale-if-error="5"');
    harness.clock.advance(const Duration(seconds: 2));
    final response = await harness.interceptor.handle(_get(), (_) async => throw _offline);
    expect(response.data, 'cached');
    expect(response.fromCache, isTrue);
    harness.clock.advance(const Duration(seconds: 4));
    await expectLater(harness.interceptor.handle(_get(), (_) async => throw _offline), throwsA(_offline));
  });

  for (final error in <Object>[
    const Failure(code: FailureCode.authUnauthorized, message: '401', kind: FailureKind.authentication),
    const Failure(code: FailureCode.cancelled, message: 'cancelled', kind: FailureKind.cancelled),
    const Failure(code: FailureCode.storageReadFailed, message: 'storage', kind: FailureKind.storage),
    StateError('programmer error'),
  ]) {
    test('stale-if-error does not hide $error', () async {
      final harness = _Harness();
      await harness.seed('max-age=1, stale-if-error=60');
      harness.clock.advance(const Duration(seconds: 2));
      await expectLater(harness.interceptor.handle(_get(), (_) async => throw error), throwsA(same(error)));
    });
  }

  for (final status in [401, 403, 500]) {
    test('HTTP $status is not silently replaced with stale data', () async {
      final harness = _Harness();
      await harness.seed('max-age=1, stale-if-error=60');
      harness.clock.advance(const Duration(seconds: 2));
      final response = await harness.interceptor.handle(_get(), (_) async => HttpResponse(statusCode: status));
      expect(response.statusCode, status);
      expect(response.fromCache, isFalse);
      expect(await harness.cache.read(const CacheKeyBuilder().build(_get())), isNull);
    });
  }

  test('cancelled requests cannot return fresh or stale cache', () async {
    final harness = _Harness();
    await harness.seed('max-age=60, stale-if-error=60');
    final cancel = HttpCancelToken()..cancel();
    await expectLater(harness.interceptor.handle(_get().copyWith(cancelToken: cancel),
        (_) async => throw StateError('must not call network')), throwsA(isA<Failure>().having((f) => f.isCancelled, 'cancelled', isTrue)));
  });

  test('mutation errors propagate without cache fallback', () async {
    final harness = _Harness();
    await harness.seed('max-age=60, stale-if-error=60');
    await expectLater(harness.interceptor.handle(_get().copyWith(method: HttpMethod.post),
        (_) async => throw _offline), throwsA(_offline));
    final response = await harness.interceptor.handle(_get().copyWith(method: HttpMethod.delete),
        (_) async => const HttpResponse(statusCode: 401));
    expect(response.statusCode, 401);
    expect(response.fromCache, isFalse);
  });

  test('304 merges cache directives and can prohibit further caching', () async {
    final harness = _Harness();
    await harness.seed('max-age=1');
    harness.clock.advance(const Duration(seconds: 2));
    final validated = await harness.interceptor.handle(_get(), (_) async => const HttpResponse(
      statusCode: 304, headers: {'cache-control': ['private, max-age=60']},
    ));
    expect(validated.data, 'cached');
    expect(await harness.cache.read(const CacheKeyBuilder().build(_get())), isNull);
  });

  test('304 no-cache metadata forces the next request to revalidate', () async {
    final harness = _Harness();
    await harness.seed('max-age=1');
    harness.clock.advance(const Duration(seconds: 2));
    await harness.interceptor.handle(_get(), (_) async => const HttpResponse(
      statusCode: 304, headers: {'Cache-Control': ['no-cache, max-age=60']},
    ));
    var calls = 0;
    await harness.interceptor.handle(_get(), (_) async {
      calls++;
      return const HttpResponse(statusCode: 304);
    });
    expect(calls, 1);
  });

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
