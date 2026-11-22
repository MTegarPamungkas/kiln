import 'deep_link_config.dart';

/// Rejects links whose scheme or host is not configured.
final class LinkAllowlist {
  LinkAllowlist({this.config = DeepLinkConfig.defaults})
    : _scheme = config.schemeName,
      _hosts = <String>{
        for (final host in config.allowedHosts)
          if (host.trim().isNotEmpty) host.trim().toLowerCase(),
      },
      _customHosts = <String>{
        for (final host in config.customSchemeHosts)
          if (host.trim().isNotEmpty) host.trim().toLowerCase(),
      },
      _prefixes = _tidyPrefixes(config.pathPrefixes);

  final DeepLinkConfig config;
  final String _scheme;
  final Set<String> _hosts;
  final Set<String> _customHosts;
  final List<String> _prefixes;

  /// Whether `https` links can pass at all.
  bool get acceptsUniversalLinks => _hosts.isNotEmpty;

  /// Whether `https` links must match a configured path prefix.
  bool get restrictsPaths => _prefixes.isNotEmpty;

  /// Whether [link] may reach the router.
  bool allows(Uri link) {
    final scheme = link.scheme.toLowerCase();
    if (scheme.isEmpty ||
        const {'http', 'file', 'javascript', 'data', 'about', 'mailto', 'tel', 'sms'}
            .contains(scheme) ||
        link.userInfo.isNotEmpty || _unsafePath(link.path)) {
      return false;
    }
    if (scheme == _scheme && scheme != 'https') {
      if ((_customHosts.isNotEmpty && !_customHosts.contains(link.host.toLowerCase())) ||
          link.hasPort || (!link.hasAuthority && !link.path.startsWith('/'))) {
        return false;
      }
      final path = link.host.isEmpty ? link.path : '/${link.host}${link.path}';
      return _matchesPath(Uri(path: path).normalizePath().path);
    }
    if (scheme != 'https') {
      return false;
    }
    if (!_hosts.contains(link.host.toLowerCase())) {
      return false;
    }
    return _matchesPath(link.normalizePath().path);
  }

  static bool _unsafePath(String path) {
    try {
      final decoded = Uri.decodeComponent(path);
      return decoded.contains('\\') ||
          decoded.codeUnits.any((unit) => unit < 32) ||
          RegExp(r'%2e|%2f|%5c', caseSensitive: false).hasMatch(decoded) ||
          decoded.split('/').any((segment) => segment == '.' || segment == '..');
    } on FormatException {
      return true;
    }
  }

  bool _matchesPath(String path) {
    if (_prefixes.isEmpty) {
      return true;
    }
    final value = path.isEmpty ? '/' : path;
    return _prefixes.any((prefix) => _matchesPrefix(value, prefix));
  }

  static bool _matchesPrefix(String path, String prefix) {
    if (prefix == '/') {
      return true;
    }
    if (!path.startsWith(prefix)) {
      return false;
    }
    return path.length == prefix.length || path[prefix.length] == '/';
  }

  static List<String> _tidyPrefixes(List<String> prefixes) {
    final result = <String>[];
    for (final prefix in prefixes) {
      final tidied = _tidyPrefix(prefix);
      if (tidied.isNotEmpty) {
        result.add(tidied);
      }
    }
    return result;
  }

  static String _tidyPrefix(String prefix) {
    final value = prefix.trim();
    if (value.isEmpty) {
      return '';
    }
    final withSlash = value.startsWith('/') ? value : '/$value';
    if (withSlash.length > 1 && withSlash.endsWith('/')) {
      return withSlash.substring(0, withSlash.length - 1);
    }
    return withSlash;
  }
}
