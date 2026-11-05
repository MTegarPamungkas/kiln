import 'package:mason/mason.dart' show MasonBundle;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import '../kiln_exception.dart';
import 'compatibility.dart';
import 'contribution.dart';
import 'platform_setup.dart';
import 'prompt_spec.dart';
import 'slot.dart';

/// Trust tier assigned to an extension by the registry.
enum ExtensionTier { official, verified, community }

/// Where an extension came from.
enum ExtensionSource { bundled, store }

/// A manual step the user must finish after installation.
final class ManualStep {
  const ManualStep({required this.id, required this.description});

  final String id;
  final String description;

  static ManualStep fromMap(Map<String, Object?> map) {
    return ManualStep(
      id: '${map['id'] ?? ''}',
      description: '${map['description'] ?? ''}',
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'description': description,
  };
}

/// Everything `extension.yaml` declares.
final class ExtensionManifest {
  const ExtensionManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.category,
    this.tier = ExtensionTier.community,
    this.exclusive = false,
    this.provides = const <String>[],
    this.requires = const <String>[],
    this.optionalRequires = const <String>[],
    this.dependencies = const <String, Object?>{},
    this.devDependencies = const <String, Object?>{},
    this.slots = const <SlotDeclaration>[],
    this.contributions = const <Contribution>[],
    this.prompts = const <PromptSpec>[],
    this.platformSetup = const PlatformSetup(),
    this.manualSteps = const <ManualStep>[],
    this.compatibility = const Compatibility(),
    this.rootPath,
    this.raw = const <String, Object?>{},
  });

  factory ExtensionManifest.parse(String source, {String? rootPath}) {
    final document = loadYaml(source);
    if (document is! Map) {
      throw const KilnException(
        'extension.yaml must contain a map',
        code: 'manifest.invalid_root',
      );
    }
    return ExtensionManifest.fromMap(_asMap(document), rootPath: rootPath);
  }

  factory ExtensionManifest.fromMap(
    Map<String, Object?> map, {
    String? rootPath,
  }) {
    final platforms = _stringList(map['platforms']);
    return ExtensionManifest(
      id: '${map['id'] ?? ''}',
      name: '${map['name'] ?? ''}',
      version: '${map['version'] ?? ''}',
      description: '${map['description'] ?? ''}',
      category: '${map['category'] ?? ''}',
      tier: _tier(map['tier']),
      exclusive: map['exclusive'] == true,
      provides: _stringList(map['provides']),
      requires: _stringList(map['requires']),
      optionalRequires: _stringList(map['optional_requires']),
      dependencies: _objectMap(map['dependencies']),
      devDependencies: _objectMap(map['dev_dependencies']),
      slots: _list(map['slots'])
          .map((entry) => SlotDeclaration.fromMap(_asMap(entry)))
          .toList(growable: false),
      contributions: _list(map['contributes'])
          .map((entry) => Contribution.fromMap(_asMap(entry)))
          .toList(growable: false),
      prompts: _list(map['prompts'])
          .map((entry) => PromptSpec.fromMap(_asMap(entry)))
          .toList(growable: false),
      platformSetup: PlatformSetup.fromMap(
        android: _asMap(map['android']),
        ios: _asMap(map['ios']),
        macos: _asMap(map['macos']),
        web: _asMap(map['web']),
        conditionals: _list(map['conditional']),
        platforms: platforms,
      ),
      manualSteps: _list(map['manual_steps'])
          .map((entry) => ManualStep.fromMap(_asMap(entry)))
          .toList(growable: false),
      compatibility: Compatibility.fromMap(_asMap(map['compatibility'])),
      rootPath: rootPath,
      raw: map,
    );
  }

  final String id;
  final String name;
  final String version;
  final String description;
  final String category;
  final ExtensionTier tier;
  final bool exclusive;
  final List<String> provides;
  final List<String> requires;
  final List<String> optionalRequires;
  final Map<String, Object?> dependencies;
  final Map<String, Object?> devDependencies;
  final List<SlotDeclaration> slots;
  final List<Contribution> contributions;
  final List<PromptSpec> prompts;
  final PlatformSetup platformSetup;
  final List<ManualStep> manualSteps;
  final Compatibility compatibility;
  final String? rootPath;
  final Map<String, Object?> raw;

  Version get semverVersion => Version.parse(version);

  bool get isExclusiveTier =>
      tier == ExtensionTier.official || tier == ExtensionTier.verified;

  Set<String> get capabilities => {...provides};

  Map<String, PromptSpec> get promptsByName => <String, PromptSpec>{
    for (final prompt in prompts) prompt.name: prompt,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'version': version,
    'description': description,
    'category': category,
    'tier': tier.name,
    if (exclusive) 'exclusive': true,
    if (provides.isNotEmpty) 'provides': provides,
    if (requires.isNotEmpty) 'requires': requires,
    if (optionalRequires.isNotEmpty) 'optional_requires': optionalRequires,
    if (dependencies.isNotEmpty) 'dependencies': dependencies,
    if (devDependencies.isNotEmpty) 'dev_dependencies': devDependencies,
    if (slots.isNotEmpty)
      'slots': slots.map((slot) => slot.toJson()).toList(growable: false),
    if (contributions.isNotEmpty)
      'contributes': contributions
          .map((contribution) => contribution.toJson())
          .toList(growable: false),
    if (prompts.isNotEmpty)
      'prompts': prompts
          .map((prompt) => prompt.toJson())
          .toList(growable: false),
    if (manualSteps.isNotEmpty)
      'manual_steps': manualSteps
          .map((step) => step.toJson())
          .toList(growable: false),
    if (compatibility.kiln != null ||
        compatibility.dart != null ||
        compatibility.flutter != null)
      'compatibility': <String, Object?>{
        if (compatibility.kiln != null) 'kiln': compatibility.kiln,
        if (compatibility.dart != null) 'dart': compatibility.dart,
        if (compatibility.flutter != null) 'flutter': compatibility.flutter,
      },
    if (platformSetup.platforms.isNotEmpty)
      'platforms': platformSetup.platforms,
    if (!platformSetup.android.isEmpty)
      'android': platformSetup.android.toJson(),
    if (!platformSetup.ios.isEmpty) 'ios': platformSetup.ios.toJson(),
    if (!platformSetup.macos.isEmpty) 'macos': platformSetup.macos.toJson(),
    if (!platformSetup.web.isEmpty) 'web': platformSetup.web.toJson(),
    if (platformSetup.conditionals.isNotEmpty)
      'conditional': platformSetup.conditionals
          .map((conditional) => conditional.toJson())
          .toList(growable: false),
  };

  static ExtensionTier _tier(Object? value) {
    return switch ('$value') {
      'official' => ExtensionTier.official,
      'verified' => ExtensionTier.verified,
      _ => ExtensionTier.community,
    };
  }
}

/// A manifest together with the Mason bundle the CLI ships for it.
final class AvailableExtension {
  const AvailableExtension({
    required this.manifest,
    required this.bundle,
    this.source = ExtensionSource.bundled,
  });

  final ExtensionManifest manifest;
  final MasonBundle bundle;
  final ExtensionSource source;

  String get id => manifest.id;
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

List<Object?> _list(Object? value) {
  if (value is! Iterable) {
    return const <Object?>[];
  }
  return value.map(_normalize).toList(growable: false);
}

List<String> _stringList(Object? value) {
  return _list(value).map((entry) => '$entry').toList(growable: false);
}

Map<String, Object?> _objectMap(Object? value) {
  if (value is! Map) {
    return const <String, Object?>{};
  }
  return <String, Object?>{
    for (final entry in value.entries) '${entry.key}': _normalize(entry.value),
  };
}
