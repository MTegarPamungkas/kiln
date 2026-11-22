import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
import 'command_helpers.dart';

/// Installs one or more extensions transactionally.
final class AddCommand extends KilnCommand {
  AddCommand(super.context) {
    argParser
      ..addMultiOption(
        'answer',
        splitCommas: false,
        help: 'Prompt answer as name=value.',
      )
      ..addFlag('dry-run', negatable: false)
      ..addFlag('yes', abbr: 'y', negatable: false)
      ..addFlag('force', negatable: false, help: 'Overwrite conflicting files.')
      ..addFlag('no-verify', negatable: false)
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'add';

  @override
  String get description => 'Install extensions transactionally.';

  @override
  String get invocation => 'kiln add <extension...> [arguments]';

  @override
  Future<int> run() async {
    final requested = argResults!.rest;
    if (requested.isEmpty) {
      usageException('Specify at least one extension.');
    }

    final project = loadProject();
    final resolver = ExtensionResolver(extensionCatalog);
    final plan = resolver.resolve(
      installed: project.lockfile.ids,
      requested: requested.toSet(),
      hostCapabilities: const <String>{'app_basic'},
    );
    final provided = parseAnswerOptions(
      (argResults!['answer'] as List<String>).cast<String>(),
    );
    final assumeYes = argResults!['yes'] == true;
    final answers = answersForPlan(
      plan.added,
      saved: project.extensionAnswers,
      provided: provided,
      prompter: prompter.withAssumeYes(assumeYes),
    );

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
    final lock = argResults!['dry-run'] == true
        ? null
        : await ProjectLock.acquire(project.root);
    final InstallResult result;
    try {
      result = await installer.add(
        requested: requested,
        project: project.projectForTemplates,
        answers: answers,
        persistAnswers: true,
        options: InstallOptions(
          dryRun: argResults!['dry-run'] == true,
          verify: argResults!['no-verify'] != true,
          collisionPolicy: argResults!['force'] == true
              ? CollisionPolicy.overwrite
              : CollisionPolicy.ask,
          approveHooks: assumeYes,
        ),
        hostCapabilities: const <String>{'app_basic'},
      );
    } finally {
      lock?.release();
    }

    final dryRun = argResults!['dry-run'] == true;
    final verification = result.verification;
    final verificationFailed = verification != null && !verification.isSuccess;

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'status': result.hasConflicts
            ? 'conflict'
            : verificationFailed
            ? 'verification_failed'
            : dryRun
            ? 'preview'
            : 'installed',
        'committed': result.committed,
        'added': result.plan.added.map((extension) => extension.id).toList(),
        'changes': result.changes.map((change) => change.toJson()).toList(),
        'patches': result.patches,
        'warnings': result.warnings,
        'manual_steps': result.manualSteps
            .map((step) => step.step.description)
            .toList(),
        'verification': verification == null
            ? null
            : <String, Object?>{
                'pub_get': verification.pubGetExitCode,
                'analyze': verification.analyzeExitCode,
              },
        'dry_run': result.dryRun?.toJson(),
      });
    } else if (result.dryRun != null && dryRun) {
      logger.info(result.dryRun!.toText());
    } else if (!verificationFailed) {
      printChanges(logger, result.changes);
      printWarnings(logger, result.warnings);
      printManualSteps(logger, result.manualSteps);
    }

    if (result.hasConflicts) {
      logger.error('Changes were reverted because of a file conflict.');
      return ExitCodes.conflict;
    }

    if (verificationFailed) {
      logger.error('Verification failed; all changes were rolled back.');
      logger.error(verification.output);
      return ExitCodes.verification;
    }

    if (!dryRun) {
      if (result.plan.added.isEmpty) {
        logger.info('No new extensions to install.');
      } else {
        logger.success(
          'Installed extension(s): '
          '${result.plan.added.map((extension) => extension.id).join(', ')}',
        );
        for (final extension in result.plan.added) {
          logger.info(
            'Next: kiln setup ${extension.id} to review settings and remaining setup steps.',
          );
        }
      }
    }
    return ExitCodes.success;
  }
}
