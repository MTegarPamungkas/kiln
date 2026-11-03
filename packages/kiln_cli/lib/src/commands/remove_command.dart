import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
import 'command_helpers.dart';

/// Removes one extension and only deletes files that were not edited.
final class RemoveCommand extends KilnCommand {
  RemoveCommand(super.context) {
    argParser
      ..addFlag('dry-run', negatable: false)
      ..addFlag('force', negatable: false)
      ..addFlag('yes', abbr: 'y', negatable: false)
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'remove';

  @override
  String get description => 'Remove an extension.';

  @override
  String get invocation => 'kiln remove <extension> [arguments]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      usageException('Specify the extension to remove.');
    }
    final id = rest.first;
    final project = loadProject();
    final assumeYes = argResults!['yes'] == true;
    final dryRun = argResults!['dry-run'] == true;

    if (!dryRun &&
        !prompter
            .withAssumeYes(assumeYes)
            .confirm('Remove extension $id?', defaultValue: false)) {
      logger.info('Dibatalkan.');
      return ExitCodes.success;
    }

    final installer = ExtensionInstaller(
      projectRoot: project.root,
      available: extensionCatalog,
    );
    final result = await installer.remove(
      id: id,
      answers: project.extensionAnswers[id] ?? const <String, Object?>{},
      options: RemoveOptions(
        dryRun: dryRun,
        force: argResults!['force'] == true,
      ),
    );

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'id': id,
        'deleted': result.deletedFiles,
        'skipped': result.skippedFiles,
        'patches': result.revertedPatches,
        'dependencies': result.removedDependencies,
        'warnings': result.warnings,
        'dry_run': result.dryRun?.toJson(),
      });
    } else if (dryRun) {
      logger.info(result.dryRun!.toText());
    } else {
      printChanges(logger, result.changes);
      printWarnings(logger, result.warnings);
      logger.success('Extension $id removed');
    }

    if (!dryRun) {
      project.removeExtensionAnswer(id);
    }
    if (result.skippedFiles.isNotEmpty) {
      logger.warn(
        '${result.skippedFiles.length} files skipped because they were edited; '
        'use --force to remove them',
      );
    }
    return ExitCodes.success;
  }
}
