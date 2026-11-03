import 'deep_link_config.dart';

/// Builds outgoing links that point back into the application.
final class AppLinkBuilder {
  AppLinkBuilder({this.config = DeepLinkConfig.defaults});

  final DeepLinkConfig config;

  /// Builds `<scheme>://<first segment>/<rest>`, for example
  /// `kiln://profile/42` from `/profile/42`.
  Uri custom(
    String path, {
    Map<String, String> query = const <String, String>{},
  }) {
    final segments = _segments(path);
    if (segments.isEmpty) {
      throw ArgumentError.value(
        path,
        'path',
        'must contain at least one segment',
      );
    }
    final rest = segments.skip(1).toList(growable: false);
    return Uri(
      scheme: config.schemeName,
      host: segments.first.toLowerCase(),
      path: rest.isEmpty ? null : '/${rest.join('/')}',
      queryParameters: _query(query),
    );
  }

  /// Builds `https://<host>/<path>` for a universal link.
  ///
  /// [host] defaults to the first configured allowed host.
  Uri universal(
    String path, {
    String? host,
    Map<String, String> query = const <String, String>{},
  }) {
    final configured = config.allowedHosts;
    final target = host ?? (configured.isEmpty ? null : configured.first);
    if (target == null || target.trim().isEmpty) {
      throw StateError(
        'DeepLinkConfig.allowedHosts is empty; pass host explicitly.',
      );
    }
    return Uri(
      scheme: 'https',
      host: target.trim().toLowerCase(),
      path: _absolutePath(path),
      queryParameters: _query(query),
    );
  }

  List<String> _segments(String path) => path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);

  String _absolutePath(String path) {
    final segments = _segments(path);
    return segments.isEmpty ? '/' : '/${segments.join('/')}';
  }

  Map<String, String>? _query(Map<String, String> query) {
    if (query.isEmpty) {
      return null;
    }
    final keys = query.keys.toList()..sort();
    return <String, String>{for (final key in keys) key: query[key] ?? ''};
  }
}
