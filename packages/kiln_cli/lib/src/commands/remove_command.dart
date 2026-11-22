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
      ..addFlag(
        'verify',
        negatable: false,
        help: 'Run pub get and analyze after removal.',
      )
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
      logger.info('Cancelled.');
      return ExitCodes.success;
    }

    final installer = ExtensionInstaller(
      projectRoot: project.root,
      available: extensionCatalog,
      verifier: Verifier(
        runner: (executable, arguments, workingDirectory) => processRunner.run(
          executable,
          arguments,
          workingDirectory: workingDirectory,
        ),
      ),
    );
    final lock = dryRun ? null : await ProjectLock.acquire(project.root);
    final RemoveResult result;
    try {
      result = await installer.remove(
        id: id,
        answers: project.extensionAnswers[id] ?? const <String, Object?>{},
        persistAnswers: true,
        options: RemoveOptions(
          dryRun: dryRun,
          force: argResults!['force'] == true,
          verify: argResults!['verify'] == true,
        ),
      );
    } finally {
      lock?.release();
    }

    final verification = result.verification;
    final verificationFailed = verification != null && !verification.isSuccess;

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'status': verificationFailed
            ? 'verification_failed'
            : dryRun
            ? 'preview'
            : 'removed',
        'committed': result.committed,
        'id': id,
        'deleted': result.deletedFiles,
        'skipped': result.skippedFiles,
        'patches': result.revertedPatches,
        'dependencies': result.removedDependencies,
        'warnings': result.warnings,
        'verification': verification == null
            ? null
            : <String, Object?>{
                'pub_get': verification.pubGetExitCode,
                'analyze': verification.analyzeExitCode,
              },
        'dry_run': result.dryRun?.toJson(),
      });
    } else if (dryRun) {
      logger.info(result.dryRun!.toText());
    } else if (!verificationFailed) {
      printChanges(logger, result.changes);
      printWarnings(logger, result.warnings);
      logger.success('Extension $id removed');
    }

    if (verificationFailed) {
      logger.error('Verification failed; all changes were rolled back.');
      logger.error(verification.output);
      return ExitCodes.verification;
    }

    if (!dryRun && result.skippedFiles.isNotEmpty) {
      logger.warn(
        '${result.skippedFiles.length} files skipped because they were edited; '
        'use --force to remove them',
      );
    }
    return ExitCodes.success;
  }
}
