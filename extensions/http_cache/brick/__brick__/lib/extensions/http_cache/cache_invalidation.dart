import 'package:kiln_core/kiln_core.dart';

/// Computes invalidation prefixes and tags for a request.
final class CacheInvalidation {
  const CacheInvalidation();

  bool isMutation(HttpMethod method) =>
      method != HttpMethod.get && method != HttpMethod.head;

  String prefixFor(HttpRequest request) => request.resolvedUri.path;

  Set<String> tagsFor(HttpRequest request) {
    final segments = request.resolvedUri.pathSegments;
    if (segments.isEmpty) {
      return const <String>{};
    }
    return <String>{segments.first};
  }
}
