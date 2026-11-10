import 'package:path/path.dart' as p;

import 'kiln_store_exception.dart';

/// Typed configuration for a registry: main URL, optional mirror, and Git ref.
///
/// [url] and [mirror] accept an HTTP(S) URL, a `file:` URI, or a local
/// filesystem path. Local paths are normalised to `file:` URIs when a URI is
/// needed, which keeps Windows drive letters and backslashes working.
final class RegistryConfig {
  RegistryConfig({required String url, String? mirror, String ref = 'main'})
    : url = url.trim(),
      mirror = _trimmedOrNull(mirror),
      ref = ref.trim().isEmpty ? 'main' : ref.trim() {
    if (this.url.isEmpty) {
      throw const KilnStoreException(
        'Registry URL must not be empty.',
        code: 'store.invalid_config',
        suggestion: 'Set the registry to an HTTP(S), file: URL, or local path.',
      );
    }
    _base = _normalise(_expandRef(this.url, this.ref));
    final mirrorValue = this.mirror;
    if (mirrorValue != null && mirrorValue.isEmpty) {
      throw const KilnStoreException(
        'Registry mirror must not be empty when provided.',
        code: 'store.invalid_config',
      );
    }
    _mirrorBase = mirrorValue == null
        ? null
        : _normalise(_expandRef(mirrorValue, this.ref));
  }

  factory RegistryConfig.fromMap(Map<String, Object?> map) {
    final url = map['url'];
    if (url is! String) {
      throw const KilnStoreException(
        'Registry configuration is missing a "url" string.',
        code: 'store.invalid_config',
      );
    }
    final mirror = map['mirror'];
    final ref = map['ref'];
    return RegistryConfig(
      url: url,
      mirror: mirror is String ? mirror : null,
      ref: ref is String ? ref : 'main',
    );
  }

  /// Base location of the registry, kept exactly as the user supplied it.
  final String url;

  /// Optional mirror of [url].
  final String? mirror;

  /// Git branch or tag the registry was published from.
  ///
  /// When [url] or [mirror] contains the `{ref}` placeholder it is replaced by
  /// this value while resolving paths, so a configuration can track a branch or
  /// tag without duplicating the base location.
  final String ref;

  late final Uri _base;
  late final Uri? _mirrorBase;

  /// URI of the main `index.json`.
  Uri get indexUri => _base.path.endsWith('.json')
      ? _base.normalizePath()
      : resolve('index.json').normalizePath();

  /// Stable cache identity includes the complete index URI, not just its host.
  String get identity => indexUri.replace(fragment: '').toString();

  /// URI of the mirror `index.json`, or `null` when no mirror is configured.
  Uri? get mirrorIndexUri =>
      _mirrorBase == null ? null : resolve('index.json', mirror: true);

  /// Resolves [path] against the main or mirror base.
  ///
  /// The result always stays below the configured base; leading slashes in
  /// [path] are ignored so callers cannot accidentally escape the registry.
  Uri resolve(String path, {bool mirror = false}) {
    final base = mirror ? _mirrorBase : _base;
    if (base == null) {
      throw const KilnStoreException(
        'No registry mirror is configured.',
        code: 'store.invalid_config',
        suggestion: 'Set a mirror before resolving mirror paths.',
      );
    }
    final substituted = path.replaceAll('{ref}', ref);
    final relative = substituted.replaceFirst(RegExp(r'^[/\\]+'), '');
    return _asDirectory(base).resolve(relative);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'url': url,
    if (mirror != null) 'mirror': mirror,
    'ref': ref,
  };

  @override
  String toString() => 'RegistryConfig(url: $url, mirror: $mirror, ref: $ref)';

  static String _expandRef(String value, String ref) {
    return value.replaceAll('{ref}', ref);
  }

  static String? _trimmedOrNull(String? value) {
    if (value == null) {
      return null;
    }
    return value.trim();
  }

  static Uri _normalise(String raw) {
    // Check drive letters before Uri.parse: "C:/registry" would otherwise be
    // interpreted as a URI with the scheme "c".
    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(raw)) {
      return Uri.file(raw);
    }
    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) {
      final scheme = parsed.scheme.toLowerCase();
      if (scheme == 'http' || scheme == 'https' || scheme == 'file') {
        return parsed;
      }
      throw KilnStoreException(
        'Unsupported registry URL scheme "${parsed.scheme}".',
        code: 'store.invalid_config',
        suggestion: 'Use an HTTP(S) URL, a file: URI, or a local directory.',
        details: <String, Object?>{'url': raw},
      );
    }
    return Uri.file(p.absolute(raw));
  }

  static Uri _asDirectory(Uri uri) {
    if (uri.path.endsWith('/')) {
      return uri;
    }
    return uri.replace(path: '${uri.path}/');
  }
}
