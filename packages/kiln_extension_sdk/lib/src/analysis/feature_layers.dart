import 'dart:io';

import 'package:path/path.dart' as p;

/// Layers inside a feature folder, ordered from the innermost to the UI.
enum FeatureLayer { domain, data, presentation }

/// One import that breaks a documented feature boundary.
final class LayerViolation {
  const LayerViolation({
    required this.relativePath,
    required this.importUri,
    required this.message,
  });

  /// Project-relative path of the file that owns the import.
  final String relativePath;

  /// The import that crosses the boundary.
  final String importUri;

  /// What to do instead.
  final String message;

  @override
  String toString() => '$relativePath: $message';
}

final RegExp _directivePattern = RegExp(
  '''^(?:import|export)\\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Checks application sources for clean-architecture boundary violations.
///
/// [sourcesByPath] maps project-relative paths such as
/// `lib/features/notes/domain/entities/note.dart` to their source text, and
/// [packageName] is the application package used to resolve
/// `package:<name>/…` imports.
///
/// Only files inside `lib/features/<feature>/<layer>/` are examined. A
/// feature's own `feature.dart` is the composition point and deliberately
/// knows all three layers, so it is never reported, and the application shell
/// is free to reach features because wiring is its job.
List<LayerViolation> layerViolations({
  required Map<String, String> sourcesByPath,
  required String packageName,
}) {
  final violations = <LayerViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final origin = _locate(path);
    if (origin == null) {
      continue;
    }
    final source = sourcesByPath[path] ?? '';
    for (final match in _directivePattern.allMatches(source)) {
      final importUri = match.group(1)!;
      final message = _messageFor(
        origin: origin,
        importUri: importUri,
        target: _resolve(
          importerPath: path,
          importUri: importUri,
          packageName: packageName,
        ),
      );
      if (message != null) {
        violations.add(
          LayerViolation(
            relativePath: path,
            importUri: importUri,
            message: message,
          ),
        );
      }
    }
  }
  return List<LayerViolation>.unmodifiable(violations);
}

/// Reads every Dart file under `lib/` in [projectRoot], keyed by relative path.
Map<String, String> readLibSources(Directory projectRoot) {
  final lib = Directory(p.join(projectRoot.path, 'lib'));
  if (!lib.existsSync()) {
    return const <String, String>{};
  }
  final sources = <String, String>{};
  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) {
      continue;
    }
    sources[_relative(file.path, projectRoot)] = file.readAsStringSync();
  }
  return sources;
}

/// Where a file sits inside a feature, once the feature name is known.
final class _Location {
  const _Location(this.feature, this.layer);

  final String feature;
  final FeatureLayer layer;
}

FeatureLayer? _layerFromName(String name) =>
    switch (name) {
      'domain' => FeatureLayer.domain,
      'data' => FeatureLayer.data,
      'presentation' => FeatureLayer.presentation,
      _ => null,
    };

/// Classifies a lib-relative path, or null when the checker ignores it.
_Location? _locate(String relativePath) {
  final segments = p.posix.split(relativePath);
  if (segments.first != 'lib' ||
      segments.length < 4 ||
      segments[1] != 'features') {
    return null;
  }
  final layer = _layerFromName(segments[3]);
  return layer == null ? null : _Location(segments[2], layer);
}

/// Resolves an in-app import to its location, or null when it is not a file in
/// this application or not inside a layer folder.
_Location? _resolve({
  required String importerPath,
  required String importUri,
  required String packageName,
}) {
  final packagePrefix = 'package:$packageName/';
  if (importUri.startsWith(packagePrefix)) {
    return _locate('lib/${importUri.substring(packagePrefix.length)}');
  }
  if (importUri.startsWith('package:') || importUri.startsWith('dart:')) {
    return null;
  }
  return _locate(
    p.posix.normalize(
      p.posix.join(p.posix.dirname(importerPath), importUri),
    ),
  );
}

String? _messageFor({
  required _Location origin,
  required String importUri,
  required _Location? target,
}) {
  if (target == null) {
    return origin.layer == FeatureLayer.domain && _isFlutter(importUri)
        ? 'domain/ must stay framework-free: keep Flutter in presentation/ '
              'and leave only the domain result here.'
        : null;
  }

  if (target.feature != origin.feature) {
    return 'Feature "${origin.feature}" reaches into feature '
        '"${target.feature}". Import its feature.dart barrel, or move the '
        'shared code to lib/core.';
  }

  if (target.layer == origin.layer) {
    return null;
  }
  return switch ((origin.layer, target.layer)) {
    (FeatureLayer.presentation, FeatureLayer.data) =>
      'presentation/ must call domain/ use cases, not data/. Wire the '
          'repository in feature.dart instead.',
    (FeatureLayer.domain, FeatureLayer.data) ||
    (FeatureLayer.domain, FeatureLayer.presentation) ||
    (FeatureLayer.data, FeatureLayer.presentation) =>
      '${origin.layer.name}/ must not import ${target.layer.name}/: '
          'dependencies point inward.',
    _ => null,
  };
}

String _relative(String path, Directory root) =>
    p.relative(path, from: root.path).replaceAll('\\', '/');

bool _isFlutter(String importUri) =>
    importUri == 'package:flutter' || importUri.startsWith('package:flutter/');
