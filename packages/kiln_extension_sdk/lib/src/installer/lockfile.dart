import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../kiln_exception.dart';
import '../manifest/extension_manifest.dart';

/// One installed extension recorded in `kiln.lock.yaml`.
final class LockedExtension {
  const LockedExtension({
    required this.version,
    required this.source,
    this.dependencies = const <String>[],
    this.devDependencies = const <String>[],
    this.flutterGenerate,
    this.files = const <String, String>{},
    this.patches = const <String>[],
    this.manualSteps = const <String>[],
  });

  final String version;
  final ExtensionSource source;
  /// Required packages, not proof of Kiln ownership.
  final List<String> dependencies;
  final List<String>? devDependencies;
  /// Null in legacy locks: requirements are unknown and preserved conservatively.
  final bool? flutterGenerate;

  /// Relative path to SHA-256 hash. An empty hash means origin unknown.
  final Map<String, String> files;
  final List<String> patches;
  final List<String> manualSteps;

  LockedExtension copyWith({
    String? version,
    ExtensionSource? source,
    List<String>? dependencies,
    List<String>? devDependencies,
    bool? flutterGenerate,
    Map<String, String>? files,
    List<String>? patches,
    List<String>? manualSteps,
  }) {
    return LockedExtension(
      version: version ?? this.version,
      source: source ?? this.source,
      dependencies: dependencies ?? this.dependencies,
      devDependencies: devDependencies ?? this.devDependencies,
      flutterGenerate: flutterGenerate ?? this.flutterGenerate,
      files: files ?? this.files,
      patches: patches ?? this.patches,
      manualSteps: manualSteps ?? this.manualSteps,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'version': version,
    'source': source.name,
    if (dependencies.isNotEmpty) 'dependencies': dependencies,
    if (devDependencies != null) 'dev_dependencies': devDependencies,
    if (flutterGenerate != null) 'flutter_generate': flutterGenerate,
    'files': files,
    if (patches.isNotEmpty) 'patches': patches,
    if (manualSteps.isNotEmpty) 'manual_steps': manualSteps,
  };

  static LockedExtension fromMap(Map<String, Object?> map) {
    final rawFiles = map['files'];
    final files = <String, String>{};
    if (rawFiles is Map) {
      for (final entry in rawFiles.entries) {
        files['${entry.key}'] = '${entry.value ?? ''}';
      }
    } else if (rawFiles is Iterable) {
      for (final path in rawFiles) {
        files['$path'] = '';
      }
    }

    return LockedExtension(
      version: '${map['version'] ?? ''}',
      source: '${map['source'] ?? 'bundled'}' == 'store'
          ? ExtensionSource.store
          : ExtensionSource.bundled,
      dependencies: _stringList(map['dependencies']),
      devDependencies: map.containsKey('dev_dependencies')
          ? _stringList(map['dev_dependencies']) : null,
      flutterGenerate: map['flutter_generate'] as bool?,
      files: files,
      patches: _stringList(map['patches']),
      manualSteps: _stringList(map['manual_steps']),
    );
  }
}

/// The contents of `kiln.lock.yaml`.
final class Lockfile {
  const Lockfile({
    this.lockVersion = 2,
    this.core = '0.1.0',
    this.extensions = const <String, LockedExtension>{},
    this.ownedDependencies = const <String, Object?>{},
    this.ownedDevDependencies = const <String, Object?>{},
    this.ownedFlutterGenerate = const <String, Object?>{},
  });

  factory Lockfile.empty({String core = '0.1.0'}) => Lockfile(core: core);

  factory Lockfile.fromYaml(String source) {
    final document = loadYaml(source);
    if (document is! Map) {
      throw const KilnException(
        'kiln.lock.yaml must contain a map',
        code: 'lockfile.invalid',
      );
    }
    final map = _asMap(document);
    final rawExtensions = map['extensions'];
    final extensions = <String, LockedExtension>{};
    if (rawExtensions is Map) {
      for (final entry in rawExtensions.entries) {
        extensions['${entry.key}'] = LockedExtension.fromMap(
          _asMap(entry.value),
        );
      }
    }
    return Lockfile(
      lockVersion: map['lock_version'] is int ? map['lock_version']! as int : 1,
      core: '${map['core'] ?? '0.1.0'}',
      extensions: extensions,
      ownedDependencies: _asMap(map['owned_dependencies']),
      ownedDevDependencies: _asMap(map['owned_dev_dependencies']),
      ownedFlutterGenerate: _asMap(map['owned_flutter_generate']),
    );
  }

  final int lockVersion;
  final String core;
  final Map<String, LockedExtension> extensions;

  /// Only packages actually inserted by Kiln, with their installed YAML values.
  /// Missing metadata in older locks never implies ownership.
  final Map<String, Object?> ownedDependencies;
  final Map<String, Object?> ownedDevDependencies;
  /// Previous generate setting: `present` plus `value`, only when Kiln changed it.
  final Map<String, Object?> ownedFlutterGenerate;

  bool get isEmpty => extensions.isEmpty;

  Set<String> get ids => extensions.keys.toSet();

  Lockfile withExtension(String id, LockedExtension extension) {
    return Lockfile(
      core: core,
      extensions: <String, LockedExtension>{...extensions, id: extension},
      ownedDependencies: ownedDependencies,
      ownedDevDependencies: ownedDevDependencies,
      ownedFlutterGenerate: ownedFlutterGenerate,
    );
  }

  Lockfile withoutExtension(String id) {
    final copy = <String, LockedExtension>{...extensions}..remove(id);
    return Lockfile(core: core, extensions: copy,
      ownedDependencies: ownedDependencies,
      ownedDevDependencies: ownedDevDependencies,
      ownedFlutterGenerate: ownedFlutterGenerate,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'lock_version': 2,
    'core': core,
    if (ownedDependencies.isNotEmpty) 'owned_dependencies': ownedDependencies,
    if (ownedDevDependencies.isNotEmpty) 'owned_dev_dependencies': ownedDevDependencies,
    if (ownedFlutterGenerate.isNotEmpty) 'owned_flutter_generate': ownedFlutterGenerate,
    'extensions': <String, Object?>{
      for (final entry in extensions.entries) entry.key: entry.value.toJson(),
    },
  };

  String toYaml() =>
      '# Generated by kiln. Do not edit by hand.\n${_encodeYaml(toJson())}';
}

/// Reads and writes the lockfile in one project.
final class LockfileStore {
  const LockfileStore(this.projectRoot);

  final Directory projectRoot;

  File get file => File(p.join(projectRoot.path, 'kiln.lock.yaml'));

  bool get exists => file.existsSync();

  Lockfile read() {
    if (!file.existsSync()) {
      return Lockfile.empty();
    }
    return Lockfile.fromYaml(file.readAsStringSync());
  }

  void write(Lockfile lockfile) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(lockfile.toYaml());
  }
}

Map<String, Object?> _asMap(Object? value) {
  if (value is! Map) {
    return const <String, Object?>{};
  }
  return <String, Object?>{
    for (final entry in value.entries) '${entry.key}': entry.value,
  };
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) {
    return const <String>[];
  }
  return value.map((entry) => '$entry').toList(growable: false);
}

String _encodeYaml(Object? value, [int indent = 0]) {
  final buffer = StringBuffer();
  _writeYaml(value, buffer, indent);
  return buffer.toString();
}

void _writeYaml(Object? value, StringBuffer buffer, int indent) {
  final pad = '  ' * indent;
  if (value is Map) {
    if (value.isEmpty) {
      buffer.writeln('$pad{}');
      return;
    }
    for (final entry in value.entries) {
      final key = _yamlKey('${entry.key}');
      final child = entry.value;
      if (child is Map || child is List) {
        if (child is Map && child.isEmpty) {
          buffer.writeln('$pad$key: {}');
        } else if (child is List && child.isEmpty) {
          buffer.writeln('$pad$key: []');
        } else {
          buffer.writeln('$pad$key:');
          _writeYaml(child, buffer, indent + 1);
        }
      } else {
        buffer.writeln('$pad$key: ${_yamlScalar(child)}');
      }
    }
    return;
  }
  if (value is List) {
    if (value.isEmpty) {
      buffer.writeln('$pad[]');
      return;
    }
    for (final item in value) {
      if (item is Map || item is List) {
        buffer.writeln('$pad-');
        _writeYaml(item, buffer, indent + 1);
      } else {
        buffer.writeln('$pad- ${_yamlScalar(item)}');
      }
    }
    return;
  }
  buffer.writeln('$pad${_yamlScalar(value)}');
}

String _yamlKey(String key) {
  final simple = RegExp(r'^[A-Za-z0-9_.-]+$');
  return simple.hasMatch(key) ? key : jsonEncode(key);
}

String _yamlScalar(Object? value) {
  if (value == null) {
    return 'null';
  }
  if (value is num || value is bool) {
    return '$value';
  }
  return jsonEncode('$value');
}
