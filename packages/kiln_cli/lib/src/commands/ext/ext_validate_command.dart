import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

import '../../command_context.dart';
import '../../infra/exit_codes.dart';
import '../../infra/json_reporter.dart';

/// Validates one `extension.yaml`.
final class ExtValidateCommand extends KilnCommand {
  ExtValidateCommand(super.context) {
    argParser.addFlag('json', negatable: false);
  }

  @override
  String get name => 'validate';

  @override
  String get description => 'Validate an extension manifest.';

  @override
  String get invocation => 'kiln ext validate [path]';

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
    final validator = const ManifestValidator();
    final errors = validator.validate(manifest);

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw)
          .write(<String, Object?>{'valid': errors.isEmpty, 'errors': errors});
    } else if (errors.isEmpty) {
      logger.success('${manifest.id} valid');
    } else {
      logger.error('${manifest.id} is invalid:');
      for (final error in errors) {
        logger.error('  - $error');
      }
    }
    return errors.isEmpty ? ExitCodes.success : ExitCodes.project;
  }
}
