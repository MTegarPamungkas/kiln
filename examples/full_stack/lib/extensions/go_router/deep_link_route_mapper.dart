/// Maps an incoming [Uri] from the `DeepLinks` contract to a router location.
final class DeepLinkRouteMapper {
  const DeepLinkRouteMapper({
    this.ignoredSchemes = const <String>{
      'mailto',
      'tel',
      'sms',
      'file',
      'javascript',
      'data',
      'about',
    },
  });

  /// Schemes that never represent an in-app destination.
  final Set<String> ignoredSchemes;

  /// Returns a location such as `/orders/42?tab=items`, or `null` when the
  /// link cannot be mapped to a route.
  ///
  /// Universal links (`http`/`https`) use their path. Custom schemes treat the
  /// host as the first path segment, so `myapp://orders/42` becomes
  /// `/orders/42`. Opaque or empty links are ignored.
  String? map(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (ignoredSchemes.contains(scheme)) {
      return null;
    }
    if (scheme == 'http' || scheme == 'https' || scheme.isEmpty) {
      return _location(uri.path, uri);
    }
    final path = uri.host.isEmpty ? uri.path : '/${uri.host}${uri.path}';
    return _location(path, uri);
  }

  String? _location(String path, Uri uri) {
    if (path.isEmpty && !uri.hasQuery) {
      return null;
    }
    final normalized = path.isEmpty
        ? '/'
        : (path.startsWith('/') ? path : '/$path');
    final buffer = StringBuffer(normalized);
    if (uri.hasQuery) {
      buffer.write('?${uri.query}');
    }
    if (uri.hasFragment) {
      buffer.write('#${uri.fragment}');
    }
    return buffer.toString();
  }
}
