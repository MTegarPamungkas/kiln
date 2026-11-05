import 'dart:io';

import 'package:yaml/yaml.dart';

import '../kiln_exception.dart';

/// The parts of `pubspec.yaml` the installer reads.
final class PubspecInfo {
  const PubspecInfo({
    required this.name,
    this.dependencies = const <String, Object?>{},
    this.devDependencies = const <String, Object?>{},
    this.environment = const <String, Object?>{},
  });

  final String name;
  final Map<String, Object?> dependencies;
  final Map<String, Object?> devDependencies;
  final Map<String, Object?> environment;

  bool hasDependency(String name) => dependencies.containsKey(name);

  bool hasDevDependency(String name) => devDependencies.containsKey(name);

  bool get usesFlutterSdk {
    final flutter = dependencies['flutter'];
    return flutter is Map && flutter['sdk'] == 'flutter';
  }

  bool get usesFlutterTestSdk {
    final flutterTest = devDependencies['flutter_test'];
    return flutterTest is Map && flutterTest['sdk'] == 'flutter';
  }
}

/// Reads a project `pubspec.yaml` without modifying it.
final class PubspecReader {
  const PubspecReader(this.file);

  final File file;

  bool get exists => file.existsSync();

  PubspecInfo read() {
    if (!file.existsSync()) {
      throw KilnException(
        'pubspec.yaml not found at ${file.path}',
        code: 'project.not_a_flutter_project',
        suggestion: 'Run kiln from the root of a Flutter project',
      );
    }
    final document = loadYaml(file.readAsStringSync());
    if (document is! Map) {
      throw const KilnException(
        'pubspec.yaml must contain a map',
        code: 'pubspec.invalid',
      );
    }
    return PubspecInfo(
      name: '${document['name'] ?? ''}',
      dependencies: _asMap(document['dependencies']),
      devDependencies: _asMap(document['dev_dependencies']),
      environment: _asMap(document['environment']),
    );
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is! Map) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      for (final entry in value.entries) '${entry.key}': entry.value,
    };
  }
}
