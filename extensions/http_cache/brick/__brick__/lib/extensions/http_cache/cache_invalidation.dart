import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

final RegExp _genericPrefixSegment = RegExp(
  r'^(?:api|v\d+)$',
  caseSensitive: false,
);

/// Computes invalidation prefixes and tags for a request.
final class CacheInvalidation {
  const CacheInvalidation();

  bool isMutation(HttpMethod method) =>
      method != HttpMethod.get && method != HttpMethod.head;

  String prefixFor(HttpRequest request) => request.resolvedUri.path;

  /// Returns the resource tag for [request], skipping leading version/API
  /// prefix segments such as `/api/` or `/v1/` so mutations do not wipe the
  /// entire cache.
  Set<String> tagsFor(HttpRequest request) {
    final segments = request.resolvedUri.pathSegments;
    if (segments.isEmpty) {
      return const <String>{};
    }
    for (final segment in segments) {
      if (!_genericPrefixSegment.hasMatch(segment)) {
        return <String>{segment};
      }
    }
    return <String>{segments.first};
  }

  /// Matches [cacheKey] against [prefix] on structural path-segment boundaries
  /// so `/users/4` does not match `/users/42`.
  static bool matchesPrefix(String cacheKey, String prefix) {
    if (prefix.isEmpty) {
      return false;
    }
    if (cacheKey == prefix) {
      return true;
    }
    final path = extractPath(cacheKey);
    if (path != null) {
      return _pathMatchesPrefix(path, prefix);
    }
    if (prefix.endsWith('/')) {
      return cacheKey.startsWith(prefix);
    }
    return cacheKey.startsWith('$prefix/') || cacheKey.startsWith('$prefix?');
  }

  /// Extracts the request URI path from a `CacheKeyBuilder` JSON array key or a
  /// `method|uri` key, or returns null when [cacheKey] has no embedded URI.
  static String? extractPath(String cacheKey) {
    if (cacheKey.startsWith('[')) {
      try {
        final decoded = jsonDecode(cacheKey);
        if (decoded is List && decoded.length >= 2 && decoded[1] is String) {
          return Uri.tryParse(decoded[1] as String)?.path;
        }
      } on FormatException {
        // Plain non-JSON cache keys fall back below.
      }
    }
    final pipe = cacheKey.indexOf('|');
    if (pipe >= 0 && pipe + 1 < cacheKey.length) {
      final candidate = cacheKey.substring(pipe + 1);
      final parsed = Uri.tryParse(candidate);
      if (parsed != null && parsed.hasScheme) {
        return parsed.path;
      }
    }
    final direct = Uri.tryParse(cacheKey);
    if (direct != null && direct.hasScheme) {
      return direct.path;
    }
    return null;
  }

  static bool _pathMatchesPrefix(String path, String prefix) {
    final normalizedPrefix = prefix.length > 1 && prefix.endsWith('/')
        ? prefix.substring(0, prefix.length - 1)
        : prefix;
    final normalizedPath = path.length > 1 && path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
    if (normalizedPath == normalizedPrefix) {
      return true;
    }
    if (normalizedPrefix == '/') {
      return normalizedPath.startsWith('/');
    }
    return normalizedPath.startsWith('$normalizedPrefix/');
  }
}
