import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import 'paths.dart';

/// A detected Kiln project and its current configuration.
final class ProjectContext {
  const ProjectContext({
    required this.root,
    required this.config,
    required this.lockfile,
    required this.pubspec,
  });

  final Directory root;
  final Map<String, Object?> config;
  final Lockfile lockfile;
  final PubspecInfo pubspec;

  File get configFile => File(Paths.kilnConfig(root));

  File get pubspecFile => File(p.join(root.path, 'pubspec.yaml'));

  Map<String, Object?> get project => _asMap(config['project']);

  String get appName => '${project['name'] ?? pubspec.name}';

  String get org => '${project['org'] ?? 'com.example'}';

  String get state => '${config['state'] ?? 'none'}';

  List<String> get platforms => _stringList(project['platforms']);

  Map<String, Map<String, Object?>> get extensionAnswers {
    final raw = config['extensions'];
    if (raw is! Map) {
      return const <String, Map<String, Object?>>{};
    }
    return <String, Map<String, Object?>>{
      for (final entry in raw.entries) '${entry.key}': _asMap(entry.value),
    };
  }

  Map<String, Object?> get projectForTemplates => <String, Object?>{
    'name': appName,
    'org': org,
    'state': state,
    'platforms': platforms,
  };

  static Directory? findRoot(Directory start) {
    var current = start.absolute;
    while (true) {
      if (File(Paths.kilnConfig(current)).existsSync()) {
        return current;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        return null;
      }
      current = parent;
    }
  }

  static ProjectContext? find(Directory start) {
    final root = findRoot(start);
    if (root == null) {
      return null;
    }
    return _loadRoot(root);
  }

  static ProjectContext load(Directory start) {
    final project = find(start);
    if (project == null) {
      throw const KilnException(
        'No Kiln project found in this folder',
        code: 'project.not_found',
        suggestion: 'Run the command from a project folder or create one with kiln create',
      );
    }
    return project;
  }

  static ProjectContext _loadRoot(Directory root) {
    final configFile = File(Paths.kilnConfig(root));
    final document = loadYaml(configFile.readAsStringSync());
    final config = _asMap(document);
    final pubspecFile = File(p.join(root.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw KilnException(
        'pubspec.yaml not found at ${root.path}',
        code: 'project.not_found',
        suggestion: 'Make sure this folder is a valid Flutter project',
      );
    }
    return ProjectContext(
      root: root,
      config: config,
      lockfile: LockfileStore(root).read(),
      pubspec: PubspecReader(pubspecFile).read(),
    );
  }

  void updateExtensionAnswers(String id, Map<String, Object?> answers) {
    final editor = YamlEditor(configFile.readAsStringSync());
    var root = editor.parseAt(<Object>[]);
    if (root is! YamlMap) {
      editor.update(<Object>[], <String, Object?>{});
      root = editor.parseAt(<Object>[]);
    }
    if (root is YamlMap && !root.containsKey('extensions')) {
      editor.update(<Object>['extensions'], <String, Object?>{});
    }
    editor.update(<Object>['extensions', id], answers);
    configFile.writeAsStringSync(editor.toString());
  }

  void removeExtensionAnswer(String id) {
    final editor = YamlEditor(configFile.readAsStringSync());
    final root = editor.parseAt(<Object>[]);
    if (root is! YamlMap || !root.containsKey('extensions')) {
      return;
    }
    final node = editor.parseAt(<Object>['extensions']);
    if (node is! YamlMap || !node.containsKey(id)) {
      return;
    }
    editor.remove(<Object>['extensions', id]);
    configFile.writeAsStringSync(editor.toString());
  }
}

Map<String, Object?> _asMap(Object? value) {
  if (value is! Map) {
    return const <String, Object?>{};
  }
  return <String, Object?>{
    for (final entry in value.entries) '${entry.key}': _normalize(entry.value),
  };
}

Object? _normalize(Object? value) {
  if (value is Map) {
    return _asMap(value);
  }
  if (value is Iterable) {
    return value.map(_normalize).toList(growable: false);
  }
  return value;
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) {
    return const <String>[];
  }
  return value.map((entry) => '$entry').toList(growable: false);
}
