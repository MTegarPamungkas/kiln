import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'cache_control_parser.dart';
import 'cache_invalidation.dart';
import 'cache_key.dart';
import 'cache_policy.dart';
import 'cache_settings.dart';
import 'etag_validator.dart';
import 'stale_while_revalidate.dart';

/// Middleware that serves and stores HTTP responses.
final class CacheInterceptor implements HttpMiddleware {
  CacheInterceptor({
    required this.cache,
    this.settings = HttpCacheSettings.defaults,
    this.clock = const SystemClock(),
    this.policy = const HttpCachePolicy(),
    this.keyBuilder = const CacheKeyBuilder(),
    this.invalidation = const CacheInvalidation(),
    this.etagValidator = const EtagValidator(),
    this.staleWhileRevalidate = const StaleWhileRevalidate(),
    this.parser = const CacheControlParser(),
  });

  final HttpCache cache;
  final HttpCacheSettings settings;
  final Clock clock;
  final HttpCachePolicy policy;
  final CacheKeyBuilder keyBuilder;
  final CacheInvalidation invalidation;
  final EtagValidator etagValidator;
  final StaleWhileRevalidate staleWhileRevalidate;
  final CacheControlParser parser;

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    request.cancelToken?.throwIfCancelled();
    if (invalidation.isMutation(request.method)) {
      final response = await next(request);
      await cache.invalidate(invalidation.prefixFor(request));
      return response;
    }
    if (!policy.allowsRequest(request)) {
      return next(request);
    }

    final key = keyBuilder.build(request);
    var entry = await cache.read(key);
    if (entry != null && !_cacheable(request, entry.response)) {
      await cache.invalidate(key);
      entry = null;
    }
    request.cancelToken?.throwIfCancelled();
    final requestControl = policy.requestControl(request);
    final control = _control(entry?.response);
    final now = clock.now().toUtc();
    if (entry != null && !requestControl.noCache && !control.noCache &&
        entry.isFresh(now)) {
      return entry.response.copyWith(fromCache: true);
    }

    if (entry != null && !requestControl.noCache &&
        staleWhileRevalidate.canServe(
          entry: entry,
          control: control,
          clock: clock,
          enabled: settings.staleWhileRevalidate,
        )) {
      unawaited(_refresh(key, request, next));
      return entry.response.copyWith(fromCache: true);
    }

    final etag = etagValidator.ifNoneMatch(request, entry);
    final outgoing = etag == null
        ? request
        : request.copyWith(
            headers: <String, String>{
              for (final header in request.headers.entries)
                if (header.key.toLowerCase() != 'if-none-match')
                  header.key: header.value,
              'If-None-Match': etag,
            },
          );

    final HttpResponse response;
    try {
      response = await next(outgoing);
    } on Failure catch (failure) {
      request.cancelToken?.throwIfCancelled();
      if (entry != null && !requestControl.noCache &&
          policy.isTransient(failure) &&
          policy.canServeOnError(entry, control, clock.now().toUtc())) {
        return entry.response.copyWith(fromCache: true);
      }
      rethrow;
    }
    request.cancelToken?.throwIfCancelled();
    if (etag != null && etagValidator.isNotModified(response) && entry != null) {
      final updatedNames = response.headers.keys.map((name) => name.toLowerCase()).toSet();
      final validated = entry.response.copyWith(headers: <String, List<String>>{
        for (final header in entry.response.headers.entries)
          if (!updatedNames.contains(header.key.toLowerCase())) header.key: header.value,
        ...response.headers,
      });
      await _store(key, request, validated);
      return validated.copyWith(fromCache: true);
    }
    await _store(key, request, response);
    return response;
  }

  CacheControl _control(HttpResponse? response) => parser.parse(
    response == null ? null : policy.responseHeader(response, 'cache-control'),
  );

  bool _cacheable(HttpRequest request, HttpResponse response) => policy.isCacheable(
    request, response, _control(response), settings, keyBuilder: keyBuilder,
  );

  Future<void> _store(String key, HttpRequest request, HttpResponse response) async {
    if (_cacheable(request, response)) {
      await cache.write(
        key, response,
        ttl: policy.ttlFor(_control(response), settings),
        tags: invalidation.tagsFor(request),
      );
    } else {
      await cache.invalidate(key);
    }
  }

  Future<void> _refresh(String key, HttpRequest request, HttpHandler next) async {
    try {
      final response = await next(request);
      request.cancelToken?.throwIfCancelled();
      await _store(key, request, response);
    } on Exception {
      // The explicitly permitted stale response was already served.
    }
  }
}
