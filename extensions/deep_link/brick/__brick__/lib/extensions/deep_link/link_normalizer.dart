import 'deep_link_config.dart';

/// Normalizes incoming links before allowlisting and deduplication.
///
/// The scheme and host are lowercased, repeated and trailing slashes in the
/// path are removed, tracking query parameters are dropped, fragments are
/// removed, and explicit default ports are stripped.
final class LinkNormalizer {
  LinkNormalizer({this.config = DeepLinkConfig.defaults});

  final DeepLinkConfig config;

  Uri normalize(Uri link) {
    final scheme = link.scheme.toLowerCase();
    final port = link.hasPort && link.port != _defaultPort(scheme)
        ? link.port
        : null;
    final parameters = _queryParameters(link.queryParametersAll);
    return Uri(
      scheme: scheme,
      userInfo: link.userInfo.isEmpty ? null : link.userInfo,
      host: link.host.toLowerCase(),
      port: port,
      path: _path(link.path),
      queryParameters: parameters.isEmpty ? null : parameters,
      fragment: _fragment(link),
    );
  }

  String _path(String path) {
    if (path.isEmpty) {
      return path;
    }
    final collapsed = path.replaceAll(RegExp('/{2,}'), '/');
    if (collapsed.length > 1 && collapsed.endsWith('/')) {
      return collapsed.substring(0, collapsed.length - 1);
    }
    return collapsed;
  }

  Map<String, Object> _queryParameters(Map<String, List<String>> all) {
    final kept = <String, Object>{};
    for (final entry in all.entries) {
      if (config.stripTrackingParameters &&
          config.trackingParameters.contains(entry.key.toLowerCase())) {
        continue;
      }
      kept[entry.key] = entry.value.length == 1 ? entry.value.single : entry.value;
    }
    return kept;
  }

  String? _fragment(Uri link) {
    if (config.dropFragment) {
      return null;
    }
    return link.hasFragment ? link.fragment : null;
  }

  static int _defaultPort(String scheme) {
    return switch (scheme) {
      'http' => 80,
      'https' => 443,
      _ => 0,
    };
  }
}
