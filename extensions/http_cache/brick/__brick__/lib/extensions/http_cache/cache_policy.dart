import 'package:kiln_core/kiln_core.dart';

import 'cache_control_parser.dart';
import 'cache_settings.dart';

/// Decides whether a response may be stored and for how long.
final class HttpCachePolicy {
  const HttpCachePolicy();

  bool isCacheable(
    HttpRequest request,
    HttpResponse response,
    CacheControl control,
    HttpCacheSettings settings,
  ) {
    if (request.method != HttpMethod.get &&
        request.method != HttpMethod.head) {
      return false;
    }
    if (control.noStore) {
      return false;
    }
    if (!settings.cacheableStatusCodes.contains(response.statusCode)) {
      return false;
    }
    if (response.header('Set-Cookie') != null) {
      return false;
    }
    return true;
  }

  Duration ttlFor(CacheControl control, HttpCacheSettings settings) {
    if (control.noCache) {
      return Duration.zero;
    }
    return control.maxAge ?? settings.defaultTtl;
  }
}
