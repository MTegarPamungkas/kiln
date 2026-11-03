import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

Directory get fixturesRoot =>
    Directory(p.join(Directory.current.path, 'test', 'fixtures'));

Directory manifestFixture(String relativePath) =>
    Directory(p.join(fixturesRoot.path, 'manifests', relativePath));

String readText(String relativePath) =>
    File(p.join(fixturesRoot.path, relativePath)).readAsStringSync();

ExtensionManifest manifestFixtureByName(String name) =>
    ExtensionManifest.parse(readText('manifests/valid/$name.yaml'));

MasonBundle bundleFromFixture(String name) =>
    createBundle(Directory(p.join(fixturesRoot.path, 'bricks', name)));

AvailableExtension extensionFixture(String name) {
  final manifest = manifestFixtureByName(name);
  return AvailableExtension(
    manifest: manifest,
    bundle: MasonBundle(
      name: manifest.id,
      description: manifest.description,
      version: manifest.version,
    ),
  );
}

AvailableExtension makeExtension({
  required String id,
  String? name,
  String version = '1.0.0',
  String category = 'tooling',
  bool exclusive = false,
  List<String> provides = const <String>[],
  List<String> requires = const <String>[],
  List<String> optionalRequires = const <String>[],
  Map<String, Object?> dependencies = const <String, Object?>{},
  Map<String, Object?> devDependencies = const <String, Object?>{},
  List<SlotDeclaration> slots = const <SlotDeclaration>[],
  List<Contribution> contributions = const <Contribution>[],
  List<PromptSpec> prompts = const <PromptSpec>[],
  PlatformSetup platformSetup = const PlatformSetup(),
  List<ManualStep> manualSteps = const <ManualStep>[],
  MasonBundle? bundle,
}) {
  return AvailableExtension(
    manifest: ExtensionManifest(
      id: id,
      name: name ?? id,
      version: version,
      description: 'Extension $id for tests',
      category: category,
      exclusive: exclusive,
      provides: provides,
      requires: requires,
      optionalRequires: optionalRequires,
      dependencies: dependencies,
      devDependencies: devDependencies,
      slots: slots,
      contributions: contributions,
      prompts: prompts,
      platformSetup: platformSetup,
      manualSteps: manualSteps,
    ),
    bundle:
        bundle ??
        MasonBundle(name: id, description: '$id bundle', version: version),
  );
}

Future<Directory> copyProjectFixture(String name) async {
  final source = Directory(p.join(fixturesRoot.path, 'projects', name));
  final target = await Directory.systemTemp.createTemp('kiln_project_');
  await _copyDirectory(source, target);
  return target;
}

Future<Directory> newTempDirectory([String prefix = 'kiln_test_']) =>
    Directory.systemTemp.createTemp(prefix);

Future<void> _copyDirectory(Directory source, Directory target) async {
  for (final entity in source.listSync(recursive: true)) {
    final relative = p.relative(entity.path, from: source.path);
    final destination = p.join(target.path, relative);
    if (entity is Directory) {
      await Directory(destination).create(recursive: true);
    } else if (entity is File) {
      await Directory(p.dirname(destination)).create(recursive: true);
      await entity.copy(destination);
    }
  }
}
