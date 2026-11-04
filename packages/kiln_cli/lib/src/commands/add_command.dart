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
    );
    final result = await installer.add(
      requested: requested,
      project: project.projectForTemplates,
      answers: answers,
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

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'added': result.plan.added.map((extension) => extension.id).toList(),
        'changes': result.changes.map((change) => change.toJson()).toList(),
        'patches': result.patches,
        'warnings': result.warnings,
        'manual_steps': result.manualSteps
            .map((step) => step.step.description)
            .toList(),
        'verification': result.verification == null
            ? null
            : <String, Object?>{
                'pub_get': result.verification!.pubGetExitCode,
                'analyze': result.verification!.analyzeExitCode,
              },
        'dry_run': result.dryRun?.toJson(),
      });
    } else if (result.dryRun != null && argResults!['dry-run'] == true) {
      logger.info(result.dryRun!.toText());
    } else {
      printChanges(logger, result.changes);
      printWarnings(logger, result.warnings);
      printManualSteps(logger, result.manualSteps);
    }

    if (result.hasConflicts) {
      logger.error('Changes were reverted because of a file conflict.');
      return ExitCodes.conflict;
    }

    if (argResults!['dry-run'] != true) {
      for (final extension in result.plan.added) {
        project.updateExtensionAnswers(
          extension.id,
          answers[extension.id] ?? const <String, Object?>{},
        );
      }
    }

    final verification = result.verification;
    if (verification != null && !verification.isSuccess) {
      logger.error('Verification failed.');
      logger.info(verification.output);
      return ExitCodes.verification;
    }

    if (argResults!['dry-run'] != true) {
      if (result.plan.added.isEmpty) {
        logger.info('No new extensions to install.');
      } else {
        logger.success(
          'Installed extension(s): '
          '${result.plan.added.map((extension) => extension.id).join(', ')}',
        );
      }
    }
    return ExitCodes.success;
  }
}
