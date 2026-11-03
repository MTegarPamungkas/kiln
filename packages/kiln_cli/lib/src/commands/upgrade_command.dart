import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
import '../infra/registry_support.dart';
import '../project_context.dart';
import 'command_helpers.dart';

/// Plans and applies extension upgrades from the configured registry.
final class UpgradeCommand extends KilnCommand {
  UpgradeCommand(super.context) {
    argParser
      ..addFlag('all', negatable: false)
      ..addFlag('dry-run', negatable: false)
      ..addFlag('force', negatable: false)
      ..addFlag('no-verify', negatable: false)
      ..addFlag('run-hooks', negatable: false)
      ..addFlag('yes', abbr: 'y', negatable: false)
      ..addMultiOption('answer', splitCommas: false)
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'upgrade';

  @override
  String get description => 'Upgrade installed extensions from the registry.';

  @override
  Future<int> run() async {
    final project = loadProject();
    final support = RegistrySupport.from(
      context,
      projectConfig: project.config,
    );
    if (support == null) {
      return _planBundled(project);
    }

    final index = await support.index();
    final coreVersion = Version.parse(project.lockfile.core);
    final candidates = <_Upgrade>[];
    for (final entry in project.lockfile.extensions.entries) {
      final extension = index.find(entry.key);
      if (extension == null) {
        continue;
      }
      final version = VersionResolver().resolve(
        extension,
        kilnVersion: coreVersion,
        installedVersion: entry.value.version,
      );
      if (version != null) {
        candidates.add(
          _Upgrade(
            id: entry.key,
            from: entry.value.version,
            version: version,
          ),
        );
      }
    }
    candidates.sort((left, right) => left.id.compareTo(right.id));

    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'upgrades': candidates
            .map(
              (candidate) => <String, Object?>{
                'id': candidate.id,
                'from': candidate.from,
                'to': candidate.version.version,
              },
            )
            .toList(),
        'dry_run': argResults!['dry-run'] == true,
      });
      if (argResults!['dry-run'] == true) {
        return ExitCodes.success;
      }
    }

    if (candidates.isEmpty) {
      if (argResults!['json'] != true) {
        logger.info('All extensions are already at the latest registry version.');
      }
      return ExitCodes.success;
    }
    if (argResults!['dry-run'] == true) {
      logger.info('Upgrade tersedia:');
      for (final candidate in candidates) {
        logger.info(
          '  ${candidate.id} ${candidate.from} -> ${candidate.version.version}',
        );
      }
      return ExitCodes.success;
    }

    final failures = <String>[];
    for (final candidate in candidates) {
      final applied = await _upgrade(project, support, candidate);
      if (!applied) {
        failures.add(candidate.id);
      }
    }
    if (failures.isNotEmpty) {
      logger.error('Upgrade failed for: ${failures.join(', ')}');
      return ExitCodes.conflict;
    }
    return ExitCodes.success;
  }

  Future<bool> _upgrade(
    ProjectContext project,
    RegistrySupport support,
    _Upgrade candidate,
  ) async {
    final package = await support.fetch(candidate.id, candidate.version);
    final available = package.available;
    try {
      final hooks = Directory(
        p.join(package.directory.path, 'brick', 'hooks'),
      ).existsSync();
      final decision = const TrustPolicy().evaluate(
        available.manifest,
        hasHooks: hooks,
      );
      if (!decision.allowed) {
        logger.warn('${candidate.id}: ${decision.reason}');
        return false;
      }
      if (decision.requiresConfirmation &&
          !prompter
              .withAssumeYes(argResults!['yes'] == true)
              .confirm(
                '${candidate.id}: ${decision.reason}',
                defaultValue: false,
              )) {
        logger.warn('${candidate.id}: skipped.');
        return false;
      }

      final installer = ExtensionInstaller(
        projectRoot: project.root,
        // Installed extensions must stay resolvable while the candidate is
        // validated; otherwise every other installed id looks unknown.
        available: <AvailableExtension>[
          ...extensionCatalog.where((entry) => entry.id != available.id),
          available,
        ],
      );
      final dryRemove = await installer.remove(
        id: candidate.id,
        answers:
            project.extensionAnswers[candidate.id] ?? const <String, Object?>{},
        options: const RemoveOptions(dryRun: true, force: false),
      );
      if (dryRemove.skippedFiles.isNotEmpty) {
        logger.warn(
          '${candidate.id}: files were edited by the user; upgrade skipped.',
        );
        return false;
      }

      MigrationResult? migration;
      final migrations = const MigrationLoader().load(package.directory);
      final selected = const MigrationLoader().select(
        migrations: migrations,
        installed: candidate.from,
        target: candidate.version.version,
      );
      if (selected.isNotEmpty) {
        migration = const MigrationRunner().run(
          projectRoot: project.root,
          migrations: selected,
        );
      }

      await installer.remove(
        id: candidate.id,
        answers:
            project.extensionAnswers[candidate.id] ?? const <String, Object?>{},
        options: RemoveOptions(force: argResults!['force'] == true),
      );
      final answers = answerForExtension(
        available,
        saved: project.extensionAnswers[candidate.id] ??
            const <String, Object?>{},
        provided: parseAnswerOptions(
          (argResults!['answer'] as List<String>).cast<String>(),
        ),
        prompter: prompter.withAssumeYes(argResults!['yes'] == true),
      );
      final result = await installer.add(
        requested: <String>[candidate.id],
        project: project.projectForTemplates,
        answers: <String, Map<String, Object?>>{candidate.id: answers},
        options: InstallOptions(
          verify: argResults!['no-verify'] != true,
          collisionPolicy: CollisionPolicy.overwrite,
          runHooks: argResults!['run-hooks'] == true,
          approveHooks:
              argResults!['yes'] == true && argResults!['run-hooks'] == true,
        ),
        hostCapabilities: const <String>{'app_basic'},
      );
      if (result.hasConflicts) {
        logger.warn('${candidate.id}: file conflict after upgrade.');
        return false;
      }
      project.updateExtensionAnswers(candidate.id, answers);
      logger.success(
        '${candidate.id} ${candidate.from} -> ${candidate.version.version}',
      );
      for (final message in migration?.messages ?? const <String>[]) {
        logger.info('  $message');
      }
      if (result.verification != null && !result.verification!.isSuccess) {
        logger.warn('${candidate.id}: verification failed.');
        return false;
      }
      return true;
    } finally {
      await package.dispose();
    }
  }

  int _planBundled(ProjectContext project) {
    final versions = <String, String>{
      for (final entry in project.lockfile.extensions.entries)
        entry.key: entry.value.version,
    };
    final candidates = UpgradePlanner(available: extensionCatalog).plan(
      installedVersions: versions,
      all: argResults!['all'] != false,
    );
    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'upgrades': candidates
            .map(
              (candidate) => <String, Object?>{
                'id': candidate.id,
                'from': candidate.from,
                'to': candidate.to,
              },
            )
            .toList(),
      });
      return ExitCodes.success;
    }
    if (candidates.isEmpty) {
      logger.info('All extensions are already at the latest catalog version.');
      return ExitCodes.success;
    }
    logger.info('Upgrade tersedia:');
    for (final candidate in candidates) {
      logger.info('  ${candidate.id} ${candidate.from} -> ${candidate.to}');
    }
    logger.info(
      'Configure a registry with kiln config --registry=<path|url> '
      'to run upgrades.',
    );
    return ExitCodes.success;
  }
}

final class _Upgrade {
  const _Upgrade({
    required this.id,
    required this.from,
    required this.version,
  });

  final String id;
  final String from;
  final RegistryVersion version;
}
