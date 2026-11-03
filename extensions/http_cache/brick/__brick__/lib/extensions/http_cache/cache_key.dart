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
    final varying = varyHeaders.toList(growable: false)..sort();
    final parts = <String>[
      request.method.name,
      request.resolvedUri.toString(),
      for (final name in varying) '$name=${headers[name] ?? ''}',
    ];
    return parts.join('|');
  }

  String prefixFor(HttpRequest request) => request.resolvedUri.path;
}
