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
    if (invalidation.isMutation(request.method)) {
      final response = await next(request);
      await cache.invalidate(invalidation.prefixFor(request));
      return response;
    }
    if (request.method != HttpMethod.get &&
        request.method != HttpMethod.head) {
      return next(request);
    }

    final key = keyBuilder.build(request);
    final entry = await cache.read(key);
    final now = clock.now().toUtc();
    if (entry != null && entry.isFresh(now)) {
      return entry.response.copyWith(fromCache: true);
    }

    final control = parser.parse(entry?.response.header('Cache-Control'));
    if (entry != null &&
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
              ...request.headers,
              'If-None-Match': etag,
            },
          );

    try {
      final response = await next(outgoing);
      if (etagValidator.isNotModified(response) && entry != null) {
        await cache.write(
          key,
          entry.response,
          ttl: entry.ttl ?? settings.defaultTtl,
          tags: entry.tags,
        );
        return entry.response.copyWith(fromCache: true);
      }
      final responseControl = parser.parse(response.header('Cache-Control'));
      if (policy.isCacheable(outgoing, response, responseControl, settings)) {
        await cache.write(
          key,
          response,
          ttl: policy.ttlFor(responseControl, settings),
          tags: invalidation.tagsFor(request),
        );
      }
      return response;
    } on Object {
      if (entry != null) {
        return entry.response.copyWith(fromCache: true);
      }
      rethrow;
    }
  }

  Future<void> _refresh(
    String key,
    HttpRequest request,
    HttpHandler next,
  ) async {
    try {
      final response = await next(request);
      final control = parser.parse(response.header('Cache-Control'));
      if (policy.isCacheable(request, response, control, settings)) {
        await cache.write(
          key,
          response,
          ttl: policy.ttlFor(control, settings),
          tags: invalidation.tagsFor(request),
        );
      }
    } on Object {
      // The stale response was already served.
    }
  }
}
