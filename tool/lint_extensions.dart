import 'dart:convert';
import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

/// The Mason variable a brick uses for the application package name.
const String _appNameVar = '{{app_name}}';

Future<void> main() async {
  final root = Directory.current;
  final extensions =
      Directory(p.join(root.path, 'extensions'))
          .listSync()
          .whereType<Directory>()
          .where(
            (directory) =>
                File(p.join(directory.path, 'extension.yaml')).existsSync(),
          )
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));

  var failed = false;
  for (final directory in extensions) {
    final id = p.basename(directory.path);
    final manifestFile = File(p.join(directory.path, 'extension.yaml'));
    try {
      final manifest = ExtensionManifest.parse(
        manifestFile.readAsStringSync(),
        rootPath: directory.path,
      );
      final errors = const ManifestValidator().validate(manifest);
      if (errors.isEmpty) {
        stdout.writeln('[ok]   $id');
      } else {
        failed = true;
        stderr.writeln('[fail] $id');
        for (final error in errors) {
          stderr.writeln('       - $error');
        }
      }
    } catch (error) {
      failed = true;
      stderr.writeln('[fail] $id: $error');
    }

    final layerErrors = _brickLayerErrors(directory);
    if (layerErrors.isNotEmpty) {
      failed = true;
      stderr.writeln('[fail] $id breaks the feature layer rules');
      for (final error in layerErrors) {
        stderr.writeln('       - $error');
      }
    }
  }

  if (extensions.isEmpty) {
    stdout.writeln('No extensions found.');
  }
  if (failed) {
    exitCode = 1;
  }
}

/// Runs the application layer rules over the Dart files a brick installs.
///
/// The bricks ship a sample feature, so the SDK has to obey the same boundary
/// it tells applications to keep. Template placeholders are passed through as
/// the package name because the checker only uses it to recognise in-app
/// imports.
List<String> _brickLayerErrors(Directory extensionDirectory) {
  final lib = Directory(
    p.join(extensionDirectory.path, 'brick', '__brick__', 'lib'),
  );
  if (!lib.existsSync()) {
    return const <String>[];
  }
  final sources = <String, String>{};
  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) {
      continue;
    }
    final relative = p
        .relative(file.path, from: lib.path)
        .replaceAll('\\', '/');
    sources['lib/$relative'] = utf8.decode(file.readAsBytesSync());
  }
  return layerViolations(
    sourcesByPath: sources,
    packageName: _appNameVar,
  ).map((violation) => violation.toString()).toList();
}
