import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

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
  }

  if (extensions.isEmpty) {
    stdout.writeln('No extensions found.');
  }
  if (failed) {
    exitCode = 1;
  }
}
