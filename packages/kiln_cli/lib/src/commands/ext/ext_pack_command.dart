import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;

import '../../command_context.dart';
import '../../infra/exit_codes.dart';
import '../../infra/json_reporter.dart';

/// Packs one extension into a registry-compatible `.tgz` archive.
final class ExtPackCommand extends KilnCommand {
  ExtPackCommand(super.context) {
    argParser
      ..addOption('output', help: 'Archive path.')
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'pack';

  @override
  String get description => 'Pack an extension into a .tgz archive.';

  @override
  String get invocation => 'kiln ext pack [path] [arguments]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final root = rest.isEmpty
        ? context.cwd
        : Directory(p.join(context.cwd.path, rest.first));
    final manifestFile = File(p.join(root.path, 'extension.yaml'));
    if (!manifestFile.existsSync()) {
      throw KilnException(
        'extension.yaml not found at ${root.path}',
        code: 'manifest.missing',
      );
    }
    final manifest = ExtensionManifest.parse(
      manifestFile.readAsStringSync(),
      rootPath: root.path,
    );
    final errors = const ManifestValidator().validate(manifest);
    if (errors.isNotEmpty) {
      throw KilnException(
        'Invalid extension:\n${errors.join('\n')}',
        code: 'manifest.invalid',
      );
    }

    final bytes = const ArchivePacker().pack(root);
    final outputPath =
        argResults!['output'] as String? ??
        p.join(context.cwd.path, '${manifest.id}-${manifest.version}.tgz');
    final output = File(outputPath);
    output.parent.createSync(recursive: true);
    output.writeAsBytesSync(bytes);

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'id': manifest.id,
        'version': manifest.version,
        'archive': output.path,
        'sha256': sha256Hex(bytes),
        'bytes': bytes.length,
      });
    } else {
      logger.success('Archive written to ${output.path}');
    }
    return ExitCodes.success;
  }
}
