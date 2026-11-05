import 'dart:convert';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart' show ExtensionTier;

import 'kiln_store_exception.dart';

/// The parsed `index.json` of a Kiln extension registry.
final class RegistryIndex {
  RegistryIndex({
    required this.generatedAt,
    required List<RegistryExtension> extensions,
  }) : extensions = List<RegistryExtension>.unmodifiable(extensions);

  factory RegistryIndex.parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw KilnStoreException(
        'Registry index is not valid JSON.',
        code: 'store.index_invalid',
        suggestion: error.message,
      );
    }
    final map = _asMap(decoded);
    if (map == null) {
      throw const KilnStoreException(
        'Registry index must be a JSON object.',
        code: 'store.index_invalid',
      );
    }
    if (map['schema_version'] != 1) {
      throw KilnStoreException(
        'Unsupported registry index schema version '
        '"${map['schema_version']}".',
        code: 'store.index_invalid',
        suggestion: 'Only schema_version 1 is supported.',
      );
    }
    final generatedAt = DateTime.tryParse('${map['generated_at'] ?? ''}');
    if (generatedAt == null) {
      throw const KilnStoreException(
        'Registry index has a missing or invalid "generated_at".',
        code: 'store.index_invalid',
      );
    }
    final rawExtensions = map['extensions'];
    if (rawExtensions is! List) {
      throw const KilnStoreException(
        'Registry index must contain an "extensions" array.',
        code: 'store.index_invalid',
      );
    }
    final extensions = <RegistryExtension>[];
    for (final entry in rawExtensions) {
      final extension = _asMap(entry);
      if (extension == null) {
        throw const KilnStoreException(
          'Every registry extension must be a JSON object.',
          code: 'store.index_invalid',
        );
      }
      extensions.add(RegistryExtension.fromMap(extension));
    }
    return RegistryIndex(generatedAt: generatedAt, extensions: extensions);
  }

  /// When the index was generated.
  final DateTime generatedAt;

  /// Every extension the registry knows about, sorted by id.
  final List<RegistryExtension> extensions;

  /// Finds one extension by its exact id.
  RegistryExtension? find(String id) {
    final needle = id.trim();
    for (final extension in extensions) {
      if (extension.id == needle) {
        return extension;
      }
    }
    return null;
  }

  /// Searches id, name, description, and category case-insensitively.
  ///
  /// An empty query returns every extension. Exact id matches rank first,
  /// followed by id prefixes, name prefixes, and finally substring matches;
  /// ties are ordered by id.
  List<RegistryExtension> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return extensions;
    }
    final matches = extensions
        .where((extension) => extension.matches(needle))
        .toList(growable: false);
    final sorted = matches.toList()
      ..sort((left, right) {
        final byScore = left
            .matchScore(needle)
            .compareTo(right.matchScore(needle));
        return byScore != 0 ? byScore : left.id.compareTo(right.id);
      });
    return List<RegistryExtension>.unmodifiable(sorted);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schema_version': 1,
    'generated_at': generatedAt.toUtc().toIso8601String(),
    'extensions': extensions
        .map((extension) => extension.toJson())
        .toList(growable: false),
  };

  /// Encodes the index as schema-compliant, pretty-printed JSON.
  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// One extension listed in a [RegistryIndex].
final class RegistryExtension {
  RegistryExtension({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.latest,
    required this.tier,
    required List<RegistryVersion> versions,
  }) : versions = List<RegistryVersion>.unmodifiable(versions);

  factory RegistryExtension.fromMap(Map<String, Object?> map) {
    final rawVersions = map['versions'];
    if (rawVersions is! List) {
      throw KilnStoreException(
        'Extension "${map['id']}" must contain a "versions" array.',
        code: 'store.index_invalid',
      );
    }
    final versions = <RegistryVersion>[];
    for (final entry in rawVersions) {
      final version = _asMap(entry);
      if (version == null) {
        throw KilnStoreException(
          'Every version of extension "${map['id']}" must be an object.',
          code: 'store.index_invalid',
        );
      }
      versions.add(RegistryVersion.fromMap(version));
    }
    return RegistryExtension(
      id: _requiredString(map, 'id'),
      name: _requiredString(map, 'name'),
      description: _optionalString(map, 'description'),
      category: _optionalString(map, 'category'),
      latest: _requiredString(map, 'latest'),
      tier: _parseTier(map['tier'], map['id']),
      versions: versions,
    );
  }

  final String id;
  final String name;
  final String description;
  final String category;

  /// The highest published version, mirrored from the manifest.
  final String latest;

  final ExtensionTier tier;
  final List<RegistryVersion> versions;

  /// Finds a version by its exact version string.
  RegistryVersion? findVersion(String version) {
    final needle = version.trim();
    for (final candidate in versions) {
      if (candidate.version == needle) {
        return candidate;
      }
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'latest': latest,
    'tier': tier.name,
    'versions': versions
        .map((version) => version.toJson())
        .toList(growable: false),
  };

  /// Whether [needle] occurs in any searchable field. [needle] is lower case.
  bool matches(String needle) {
    return id.toLowerCase().contains(needle) ||
        name.toLowerCase().contains(needle) ||
        description.toLowerCase().contains(needle) ||
        category.toLowerCase().contains(needle);
  }

  /// Lower is a better match. [needle] is lower case.
  int matchScore(String needle) {
    if (id == needle) {
      return 0;
    }
    if (id.startsWith(needle)) {
      return 1;
    }
    if (name.toLowerCase().startsWith(needle)) {
      return 2;
    }
    if (id.contains(needle)) {
      return 3;
    }
    return 4;
  }
}

/// One downloadable version of a registry extension.
final class RegistryVersion {
  RegistryVersion({
    required this.version,
    required this.url,
    required this.sha256,
    List<String> requires = const <String>[],
    List<String> provides = const <String>[],
    Map<String, String> compatibility = const <String, String>{},
  }) : requires = List<String>.unmodifiable(requires),
       provides = List<String>.unmodifiable(provides),
       compatibility = Map<String, String>.unmodifiable(compatibility);

  factory RegistryVersion.fromMap(Map<String, Object?> map) {
    return RegistryVersion(
      version: _requiredString(map, 'version'),
      url: _requiredString(map, 'url'),
      sha256: _requiredString(map, 'sha256'),
      requires: _stringList(map['requires']),
      provides: _stringList(map['provides']),
      compatibility: _stringMap(map['compatibility']),
    );
  }

  final String version;
  final String url;
  final String sha256;
  final List<String> requires;
  final List<String> provides;

  /// Version constraints keyed by `kiln`, `dart`, and `flutter`.
  final Map<String, String> compatibility;

  /// Resolves [url] against [indexUri].
  ///
  /// Absolute URLs are returned unchanged; relative URLs are resolved against
  /// the directory that contains `index.json`.
  Uri resolveUrl(Uri indexUri) {
    final parsed = Uri.tryParse(url);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
    return indexUri.resolve(url);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'version': version,
    'url': url,
    'sha256': sha256,
    if (requires.isNotEmpty) 'requires': requires,
    if (provides.isNotEmpty) 'provides': provides,
    if (compatibility.isNotEmpty) 'compatibility': compatibility,
  };
}

ExtensionTier _parseTier(Object? value, Object? id) {
  return switch (value) {
    'official' => ExtensionTier.official,
    'verified' => ExtensionTier.verified,
    'community' => ExtensionTier.community,
    _ => throw KilnStoreException(
      'Extension "$id" has an invalid tier "$value".',
      code: 'store.index_invalid',
      suggestion: 'Use official, verified, or community.',
    ),
  };
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw KilnStoreException(
      'Registry index field "$key" must be a non-empty string.',
      code: 'store.index_invalid',
    );
  }
  return value;
}

String _optionalString(Map<String, Object?> map, String key) {
  final value = map[key];
  return value is String ? value : '';
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((entry) => entry is String ? entry : '$entry')
      .toList(growable: false);
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) {
    return const <String, String>{};
  }
  return <String, String>{
    for (final entry in value.entries) '${entry.key}': '${entry.value}',
  };
}

Map<String, Object?>? _asMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return <String, Object?>{
    for (final entry in value.entries) '${entry.key}': _normalise(entry.value),
  };
}

Object? _normalise(Object? value) {
  if (value is Map) {
    return _asMap(value);
  }
  if (value is List) {
    return value.map(_normalise).toList(growable: false);
  }
  return value;
}
