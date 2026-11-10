import 'package:kiln_core/kiln_core.dart';

import 'cache_control_parser.dart';
import 'cache_settings.dart';
import 'cache_key.dart';

/// Decides whether a response may be stored and for how long.
final class HttpCachePolicy {
  const HttpCachePolicy();

  bool allowsRequest(HttpRequest request) {
    if (request.method != HttpMethod.get && request.method != HttpMethod.head) {
      return false;
    }
    if (request.headers.keys.any((name) =>
        const {'authorization', 'cookie', 'proxy-authorization'}
            .contains(name.toLowerCase()))) {
      return false;
    }
    return !requestControl(request).noStore;
  }

  CacheControl requestControl(HttpRequest request) =>
      const CacheControlParser().parse(request.headers.entries
          .where((entry) => entry.key.toLowerCase() == 'cache-control')
          .map((entry) => entry.value)
          .join(','));

  String responseHeader(HttpResponse response, String name) => response.headers.entries
      .where((entry) => entry.key.toLowerCase() == name.toLowerCase())
      .expand((entry) => entry.value)
      .join(',');

  bool isCacheable(
    HttpRequest request,
    HttpResponse response,
    CacheControl control,
    HttpCacheSettings settings, {
    CacheKeyBuilder keyBuilder = const CacheKeyBuilder(),
  }) {
    if (!allowsRequest(request) || control.noStore || control.isPrivate) {
      return false;
    }
    if (!settings.cacheableStatusCodes.contains(response.statusCode)) {
      return false;
    }
    if (response.headers.keys.any((name) =>
        const {'set-cookie', 'www-authenticate', 'proxy-authenticate'}
            .contains(name.toLowerCase()))) {
      return false;
    }
    final keyedHeaders = keyBuilder.varyHeaders.map((name) => name.toLowerCase()).toSet();
    final vary = responseHeader(response, 'vary').split(',');
    return vary.every((name) => name.trim().isEmpty ||
        (name.trim() != '*' && keyedHeaders.contains(name.trim().toLowerCase())));
  }

  bool canServeOnError(CacheEntry entry, CacheControl control, DateTime now) {
    final window = control.staleIfError;
    final ttl = entry.ttl;
    if (control.noCache || control.mustRevalidate || control.noStore ||
        window == null || window <= Duration.zero || ttl == null) {
      return false;
    }
    return !entry.isFresh(now) && now.isBefore(entry.storedAt.add(ttl + window));
  }

  bool isTransient(Failure failure) =>
      failure.kind == FailureKind.network &&
      (failure.code == FailureCode.networkTimeout ||
          failure.code == FailureCode.networkOffline ||
          failure.code == FailureCode.networkUnreachable);

  Duration ttlFor(CacheControl control, HttpCacheSettings settings) {
    if (control.noCache) {
      return Duration.zero;
    }
    return control.maxAge ?? settings.defaultTtl;
  }
}
