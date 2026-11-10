import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

/// Builds a cache key from the request method, URL, query, and Vary headers.
final class CacheKeyBuilder {
  const CacheKeyBuilder({
    this.varyHeaders = const <String>{'accept', 'accept-encoding'},
  });

  final Set<String> varyHeaders;

  String build(HttpRequest request) {
    final headers = request.headers.map(
      (key, value) => MapEntry(key.toLowerCase(), value),
    );
    final varying = varyHeaders.map((name) => name.toLowerCase()).toSet().toList()..sort();
    return jsonEncode(<Object?>[
      request.method.name,
      request.resolvedUri.toString(),
      <String, String?>{for (final name in varying) name: headers[name]},
    ]);
  }

  String prefixFor(HttpRequest request) => request.resolvedUri.path;
}
