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

  // Any mutation invalidates pending snapshots, including collection lists.
  int _revision = 0;
  final Map<String, Future<void>> _keyWrites = <String, Future<void>>{};
  Future<void> _invalidationBarrier = Future<void>.value();
  final Set<String> _refreshing = <String>{};
  final Map<String, Future<HttpResponse>> _inFlightGets =
      <String, Future<HttpResponse>>{};

  @override
  Future<HttpResponse> handle(HttpRequest request, HttpHandler next) async {
    request.cancelToken?.throwIfCancelled();
    if (invalidation.isMutation(request.method)) {
      final response = await next(request);
      final prefix = invalidation.prefixFor(request);
      _revision++;
      await _invalidate(prefix, tag: invalidation.tagsFor(request).firstOrNull);
      return response;
    }
    if (!policy.allowsRequest(request)) {
      return next(request);
    }

    final key = keyBuilder.build(request);
    var entry = await _read(key);
    if (entry != null && !_cacheable(request, entry.response)) {
      await _invalidateKey(key);
      entry = null;
    }
    request.cancelToken?.throwIfCancelled();
    final requestControl = policy.requestControl(request);
    final control = _control(entry?.response);
    final now = clock.now().toUtc();
    if (entry != null &&
        !requestControl.noCache &&
        !control.noCache &&
        entry.isFresh(now)) {
      return entry.response.copyWith(fromCache: true);
    }

    if (entry != null &&
        !requestControl.noCache &&
        staleWhileRevalidate.canServe(
          entry: entry,
          control: control,
          clock: clock,
          enabled: settings.staleWhileRevalidate,
        )) {
      _startRefresh(key, request, next);
      return entry.response.copyWith(fromCache: true);
    }

    final canCoalesce =
        request.method == HttpMethod.get &&
        request.cancelToken == null &&
        !requestControl.noCache;
    if (canCoalesce) {
      final existing = _inFlightGets[key];
      if (existing != null) {
        return existing;
      }
    }

    final future = _fetchAndStore(
      key: key,
      request: request,
      next: next,
      entry: entry,
      requestControl: requestControl,
      control: control,
    );
    if (!canCoalesce) {
      return future;
    }
    _inFlightGets[key] = future;
    return future.whenComplete(() {
      if (identical(_inFlightGets[key], future)) {
        _inFlightGets.remove(key);
      }
    });
  }

  Future<HttpResponse> _fetchAndStore({
    required String key,
    required HttpRequest request,
    required HttpHandler next,
    required CacheEntry? entry,
    required CacheControl requestControl,
    required CacheControl control,
  }) async {
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
    final revision = _revision;

    final HttpResponse response;
    try {
      response = await next(outgoing);
    } on Failure catch (failure) {
      request.cancelToken?.throwIfCancelled();
      if (entry != null &&
          !requestControl.noCache &&
          policy.isTransient(failure) &&
          policy.canServeOnError(entry, control, clock.now().toUtc())) {
        return entry.response.copyWith(fromCache: true);
      }
      rethrow;
    }
    request.cancelToken?.throwIfCancelled();
    if (etag != null &&
        etagValidator.isNotModified(response) &&
        entry != null) {
      final updatedNames = response.headers.keys
          .map((name) => name.toLowerCase())
          .toSet();
      final validated = entry.response.copyWith(
        headers: <String, List<String>>{
          for (final header in entry.response.headers.entries)
            if (!updatedNames.contains(header.key.toLowerCase()))
              header.key: header.value,
          ...response.headers,
        },
      );
      await _store(key, request, validated, revision: revision);
      return validated.copyWith(fromCache: true);
    }
    await _store(key, request, response, revision: revision);
    return response;
  }

  CacheControl _control(HttpResponse? response) => parser.parse(
    response == null ? null : policy.responseHeader(response, 'cache-control'),
  );

  bool _cacheable(HttpRequest request, HttpResponse response) =>
      policy.isCacheable(
        request,
        response,
        _control(response),
        settings,
        keyBuilder: keyBuilder,
      );

  void _startRefresh(String key, HttpRequest request, HttpHandler next) {
    if (_refreshing.contains(key)) {
      // One revalidation per key: a burst of stale reads must not fan out into
      // overlapping refreshes that can finish out of order.
      return;
    }
    _refreshing.add(key);
    final revision = _revision;
    unawaited(
      _refresh(
        key,
        request,
        next,
        revision,
      ).whenComplete(() => _refreshing.remove(key)),
    );
  }

  /// Stores [response] only when no mutation invalidated its path while the
  /// request was in flight.
  Future<void> _store(
    String key,
    HttpRequest request,
    HttpResponse response, {
    required int revision,
  }) => _serializeKey(key, () async {
    if (revision != _revision) return;
    if (_cacheable(request, response)) {
      try {
        await cache.write(
          key,
          response,
          ttl: policy.ttlFor(_control(response), settings),
          tags: invalidation.tagsFor(request),
        );
      } on Object {
        // A cache failure must not turn a successful exchange into a failure.
      }
    } else {
      await _invalidateDirect(key);
    }
  });

  Future<CacheEntry?> _read(String key) async {
    try {
      await _invalidationBarrier;
      final pending = _keyWrites[key];
      if (pending != null) {
        await pending;
      }
      return await cache.read(key);
    } on Object {
      return null;
    }
  }

  Future<void> _invalidateKey(String key) =>
      _serializeKey(key, () => _invalidateDirect(key));

  Future<void> _invalidate(String prefix, {String? tag}) {
    final previous = _invalidationBarrier;
    final pendingKeys = _keyWrites.values.toList(growable: false);
    final operation = () async {
      await previous;
      if (pendingKeys.isNotEmpty) {
        await Future.wait(pendingKeys);
      }
      await _invalidateDirect(prefix, tag: tag);
    }();
    _invalidationBarrier = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _invalidateDirect(String prefix, {String? tag}) async {
    try {
      await cache.invalidate(prefix, tag: tag);
    } on Object {
      // Cache maintenance is best effort; the network response still stands.
    }
  }

  Future<void> _serializeKey(String key, Future<void> Function() operation) {
    final previous = _keyWrites[key] ?? Future<void>.value();
    final barrier = _invalidationBarrier;
    late final Future<void> tracked;
    tracked = Future.wait(<Future<void>>[previous, barrier])
        .then((_) => operation())
        .then<void>((_) {}, onError: (Object _, StackTrace _) {})
        .whenComplete(() {
          if (identical(_keyWrites[key], tracked)) {
            _keyWrites.remove(key);
          }
        });
    _keyWrites[key] = tracked;
    return tracked;
  }

  Future<void> _refresh(
    String key,
    HttpRequest request,
    HttpHandler next,
    int revision,
  ) async {
    try {
      final response = await next(request);
      request.cancelToken?.throwIfCancelled();
      await _store(key, request, response, revision: revision);
    } on Object {
      // The explicitly permitted stale response was already served.
    }
  }
}
