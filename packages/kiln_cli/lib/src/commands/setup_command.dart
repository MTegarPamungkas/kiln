import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
import '../setup/extension_setup.dart';
import 'command_helpers.dart';

/// Reviews installed extension settings and applies the whole batch atomically.
final class SetupCommand extends KilnCommand {
  SetupCommand(super.context) {
    argParser
      ..addMultiOption(
        'answer',
        splitCommas: false,
        help: 'Setting as name=value or extension.name=value.',
      )
      ..addFlag(
        'all',
        negatable: false,
        help: 'Review all installed bundled extensions.',
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        negatable: false,
        help: 'Use saved settings and explicit answers without prompting.',
      )
      ..addFlag(
        'dry-run',
        negatable: false,
        help:
            'Render and check the entire setup without changing project files.',
      )
      ..addFlag(
        'no-verify',
        negatable: false,
        help: 'Skip pub get and analysis.',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Print a non-interactive JSON result.',
      );
  }

  @override
  String get name => 'setup';

  @override
  String get description => 'Review and configure installed extensions.';

  @override
  String get invocation => 'kiln setup [extension...] [--all] [arguments]';

  @override
  Future<int> run() async {
    final project = loadProject();
    final all = argResults!['all'] == true;
    final requested = argResults!.rest.toSet();
    if (all && requested.isNotEmpty) {
      usageException('Choose extension names or --all, not both.');
    }
    final json = argResults!['json'] == true;
    final rawAnswers = (argResults!['answer'] as List<String>).cast<String>();
    if (!all && requested.isEmpty) {
      if (rawAnswers.isNotEmpty) {
        usageException(
          'Choose an extension or --all before supplying answers.',
        );
      }
      final entries = <Map<String, Object?>>[];
      for (final id in project.lockfile.ids.toList()..sort()) {
        final available = findAvailableExtension(id);
        if (available == null) {
          entries.add({
            'id': id,
            'status': 'unavailable',
            'next_steps': ['Use a CLI catalog containing this extension.'],
          });
          continue;
        }
        final setup = ExtensionSetup(available.manifest);
        final issues = setup.issues(
          project.extensionAnswers[id] ?? const {},
          root: project.root,
        );
        final versionMatches =
            project.lockfile.extensions[id]!.version ==
            available.manifest.version;
        entries.add({
          'id': id,
          'status': !versionMatches
              ? 'version_mismatch'
              : issues.isEmpty
              ? 'configured'
              : 'needs_configuration',
          'settings': available.manifest.prompts
              .map((prompt) => prompt.name)
              .toList(),
          'issues': issues,
          'next_steps': setup.nextSteps,
        });
      }
      if (json) {
        JsonReporter(logger.raw)
            .write({'extensions': entries, 'connection_checked': false});
      } else {
        if (entries.isEmpty) {
          logger.info(
            'No extensions are installed. Run kiln list --available, then kiln add <extension>.',
          );
        }
        for (final entry in entries) {
          logger.info('${entry['id']}: ${entry['status']}');
        }
        logger.info(
          'Run kiln setup <extension> to review settings or kiln setup --all to review every installed extension.',
        );
      }
      return ExitCodes.success;
    }
    final ids = all
        ? (project.lockfile.ids.toList()..sort())
        : requested.toList();
    final selected = <AvailableExtension>[];
    for (final id in ids) {
      final extension = findAvailableExtension(id);
      if (extension == null) {
        throw const KilnException(
          'The extension is not in this CLI catalog.',
          code: 'setup.unavailable',
          suggestion:
              'Run kiln list --available and use a matching CLI catalog.',
        );
      }
      final installed = project.lockfile.extensions[id];
      if (installed == null) {
        throw KilnException(
          '${extension.manifest.name} is not installed.',
          code: 'setup.not_installed',
          suggestion: 'Run kiln add $id, then kiln setup $id.',
        );
      }
      if (installed.version != extension.manifest.version) {
        throw KilnException(
          'The installed $id version does not match this CLI catalog.',
          code: 'setup.version_mismatch',
          suggestion: 'Use a matching CLI version or run kiln upgrade first.',
        );
      }
      selected.add(extension);
    }
    final provided = <String, String>{};
    for (final raw in rawAnswers) {
      final separator = raw.indexOf('=');
      if (separator <= 0) {
        throw const KilnException(
          'Use --answer name=value or --answer extension.name=value.',
          code: 'setup.invalid',
        );
      }
      final key = raw.substring(0, separator);
      final matches = selected
          .where(
            (extension) => extension.manifest.prompts.any(
              (prompt) =>
                  key == prompt.name || key == '${extension.id}.${prompt.name}',
            ),
          )
          .toList();
      if (matches.length != 1) {
        throw const KilnException(
          'Unknown or ambiguous setting. Use a declared prompt name qualified as extension.name. Server credentials are not client settings.',
          code: 'setup.unknown_setting',
        );
      }
      final extension = matches.single;
      final qualified = key.startsWith('${extension.id}.')
          ? key
          : '${extension.id}.$key';
      provided[qualified] = raw.substring(separator + 1);
    }
    final interactive =
        prompter.interactive && argResults!['yes'] != true && !json;
    final answers = <String, Map<String, Object?>>{};
    final setups = <String, ExtensionSetup>{};
    for (final extension in selected) {
      final setup = ExtensionSetup(extension.manifest);
      setups[extension.id] = setup;
      if (interactive) {
        logger.info(
          'Configure ${extension.manifest.name}. Press Enter to keep a setting; use !clear to empty it.',
        );
        if (extension.manifest.prompts.any(setup.isSecret)) {
          logger.info(
            'Marked values are hidden during input and omitted from reports. Use env:VARIABLE_NAME to keep the value out of kiln.yaml and generated source; literal values are saved. Use only client-safe values.',
          );
        }
      }
      final values = setup.collect(
        saved: project.extensionAnswers[extension.id] ?? const {},
        provided: provided,
        prompter: prompter,
        interactive: interactive,
      );
      final issues = setup.issues(values, root: project.root);
      if (issues.isNotEmpty) {
        throw KilnException(
          issues.values.first,
          code: 'setup.invalid',
          suggestion:
              'Complete the extension prerequisites, then run kiln setup ${extension.id}.',
        );
      }
      answers[extension.id] = values;
    }
    final dryRun = argResults!['dry-run'] == true;
    final result =
        await ExtensionInstaller(
          projectRoot: project.root,
          available: extensionCatalog,
          verifier: Verifier(
            runner: (executable, arguments, workingDirectory) => processRunner
                .run(executable, arguments, workingDirectory: workingDirectory),
          ),
        ).configure(
          answers: answers,
          previousAnswers: project.extensionAnswers,
          project: project.projectForTemplates,
          hostCapabilities: const {'app_basic'},
          options: InstallOptions(
            dryRun: dryRun,
            verify: argResults!['no-verify'] != true,
          ),
        );
    final code = result.hasConflicts
        ? ExitCodes.conflict
        : result.success
        ? ExitCodes.success
        : ExitCodes.verification;
    final status = code != ExitCodes.success
        ? 'failed'
        : dryRun
        ? 'preview'
        : 'configured';
    if (json) {
      JsonReporter(logger.raw).write({
        if (ids.length == 1) 'service': ids.single,
        'status': status,
        'dry_run': dryRun,
        'connection_checked': false,
        'verification': result.verification == null
            ? 'not_run'
            : result.verification!.isSuccess
            ? 'passed'
            : 'failed',
        'changed_extensions': result.changedExtensions,
        'changes': result.changes.map((change) => change.toJson()).toList(),
        'extensions': [
          for (final extension in selected)
            {
              'id': extension.id,
              'status': status,
              'next_steps': setups[extension.id]!.nextSteps,
            },
        ],
        'next_steps': <dynamic>{
          for (final setup in setups.values) ...setup.nextSteps,
        }.toList(),
      });
    } else if (code != ExitCodes.success) {
      logger.error('Setup failed; no configuration changes were applied.');
      if (result.verification != null) logger.info(result.verification!.output);
    } else {
      logger.success(
        dryRun
            ? 'Setup preview; no project files changed.'
            : 'Selected extensions are locally configured.',
      );
      if (dryRun) printChanges(logger, result.changes);
      if (result.changedExtensions.isEmpty) {
        logger.info('No settings changed; generated files were left in place.');
      }
      for (final entry in setups.entries) {
        logger.info('${entry.key}:');
        if (entry.value.manifest.prompts.isEmpty) {
          logger.info('  No configurable prompts; review the steps below.');
        }
        for (final step in entry.value.nextSteps) {
          logger.info('  - $step');
        }
      }
      if (!dryRun) logger.info('Next: kiln doctor');
    }
    return code;
  }
}
