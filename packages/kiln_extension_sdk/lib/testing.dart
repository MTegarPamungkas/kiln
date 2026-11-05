import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

import 'kiln_extension_sdk.dart';

/// Helpers used by extension authors in `render_test.dart` and
/// `manifest_test.dart`.
final class ExtensionTestHarness {
  ExtensionTestHarness({required this.extensionRoot});

  final Directory extensionRoot;

  File get manifestFile => File(p.join(extensionRoot.path, 'extension.yaml'));

  Directory get brickDirectory =>
      Directory(p.join(extensionRoot.path, 'brick'));

  ExtensionManifest loadManifest() {
    return ExtensionManifest.parse(
      manifestFile.readAsStringSync(),
      rootPath: extensionRoot.path,
    );
  }

  List<String> validateManifest() {
    return const ManifestValidator().validate(loadManifest());
  }

  Future<MasonBundle> bundle() async => createBundle(brickDirectory);

  Future<List<RenderedFile>> render({
    Map<String, Object?> answers = const <String, Object?>{},
    Map<String, Object?> project = const <String, Object?>{},
  }) async {
    final manifest = loadManifest();
    final available = AvailableExtension(
      manifest: manifest,
      bundle: await bundle(),
    );
    return const BrickRenderer().render(
      bundle: available.bundle,
      vars: buildTemplateVars(
        extension: available,
        answers: answers,
        project: project,
      ),
    );
  }
}
