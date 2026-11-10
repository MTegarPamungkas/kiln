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
      return _runBundled(project);
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
          _Upgrade(id: entry.key, from: entry.value.version, version: version),
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
        logger.info(
          'All extensions are already at the latest registry version.',
        );
      }
      return ExitCodes.success;
    }
    if (argResults!['dry-run'] == true) {
      logger.info('Upgrades available:');
      for (final candidate in candidates) {
        logger.info(
          '  ${candidate.id} ${candidate.from} -> ${candidate.version.version}',
        );
      }
      return ExitCodes.success;
    }

    final failures = <String>[];
    for (final candidate in candidates) {
      final applied = await _upgrade(
        ProjectContext.load(project.root),
        support,
        candidate,
      );
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
    try {
      final available = package.available;
      final migrations = const MigrationLoader().load(package.directory);
      final selected = const MigrationLoader().select(
        migrations: migrations,
        installed: candidate.from,
        target: candidate.version.version,
      );
      return await _applyUpgrade(
        project: project,
        id: candidate.id,
        from: candidate.from,
        to: candidate.version.version,
        available: available,
        // Installed extensions must stay resolvable while the candidate is
        // validated; otherwise every other installed id looks unknown.
        availableCatalog: <AvailableExtension>[
          ...extensionCatalog.where((entry) => entry.id != available.id),
          available,
        ],
        migrations: selected,
        hasHooks: Directory(p.join(package.directory.path, 'brick', 'hooks'))
            .existsSync(),
      );
    } finally {
      await package.dispose();
    }
  }

  Future<int> _runBundled(ProjectContext project) async {
    final candidates = _bundledCandidates(project);
    final json = argResults!['json'] == true;
    final dryRun = argResults!['dry-run'] == true;

    if (json) {
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
        'dry_run': dryRun,
      });
      if (dryRun) {
        return ExitCodes.success;
      }
    }

    if (candidates.isEmpty) {
      if (!json) {
        logger.info(
          'All extensions are already at the latest catalog version.',
        );
      }
      return ExitCodes.success;
    }
    if (dryRun) {
      logger.info('Upgrades available:');
      for (final candidate in candidates) {
        logger.info('  ${candidate.id} ${candidate.from} -> ${candidate.to}');
      }
      return ExitCodes.success;
    }

    final failures = <String>[];
    for (final candidate in candidates) {
      final applied = await _upgradeBundled(
        ProjectContext.load(project.root),
        candidate,
      );
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

  List<UpgradeCandidate> _bundledCandidates(ProjectContext project) {
    final versions = <String, String>{
      for (final entry in project.lockfile.extensions.entries)
        entry.key: entry.value.version,
    };
    final candidates = UpgradePlanner(available: extensionCatalog)
        .plan(installedVersions: versions, all: argResults!['all'] != false);
    final Version core;
    try {
      core = Version.parse(project.lockfile.core);
    } on FormatException {
      return candidates;
    }
    return candidates
        .where(
          (candidate) => candidate.available.manifest.compatibility
              .problems(kilnVersion: core.toString())
              .isEmpty,
        )
        .toList(growable: false);
  }

  Future<bool> _upgradeBundled(
    ProjectContext project,
    UpgradeCandidate candidate,
  ) {
    // Bundled Dart catalogs do not embed migration files. Every bundled
    // extension currently ships without migrations; a registry upgrade still
    // loads migrations from the downloaded archive.
    return _applyUpgrade(
      project: project,
      id: candidate.id,
      from: candidate.from,
      to: candidate.to,
      available: candidate.available,
      availableCatalog: extensionCatalog,
      migrations: const <Migration>[],
      hasHooks: candidate.available.bundle.hooks.isNotEmpty,
    );
  }

  Future<bool> _applyUpgrade({
    required ProjectContext project,
    required String id,
    required String from,
    required String to,
    required AvailableExtension available,
    required List<AvailableExtension> availableCatalog,
    required List<Migration> migrations,
    required bool hasHooks,
  }) async {
    final decision = const TrustPolicy().evaluate(
      available.manifest,
      hasHooks: hasHooks,
    );
    if (!decision.allowed) {
      logger.warn('$id: ${decision.reason}');
      return false;
    }
    if (decision.requiresConfirmation &&
        !prompter
            .withAssumeYes(argResults!['yes'] == true)
            .confirm('$id: ${decision.reason}', defaultValue: false)) {
      logger.warn('$id: skipped.');
      return false;
    }

    // Resolve required answers before migrations or any installed-file writes.
    final answers = answerForExtension(
      available,
      saved: project.extensionAnswers[id] ?? const <String, Object?>{},
      provided: parseAnswerOptions(
        (argResults!['answer'] as List<String>).cast<String>(),
      ),
      prompter: prompter.withAssumeYes(argResults!['yes'] == true),
    );
    final installer = ExtensionInstaller(
      projectRoot: project.root,
      available: availableCatalog,
    );
    final result = await installer.upgrade(
      id: id,
      project: project.projectForTemplates,
      answers: answers,
      previousAnswers:
          project.extensionAnswers[id] ?? const <String, Object?>{},
      migrations: migrations,
      force: argResults!['force'] == true,
      options: InstallOptions(
        verify: argResults!['no-verify'] != true,
        runHooks: argResults!['run-hooks'] == true,
        approveHooks:
            argResults!['yes'] == true && argResults!['run-hooks'] == true,
      ),
      hostCapabilities: const <String>{'app_basic'},
    );
    if (result.hasConflicts) {
      logger.warn('$id: file conflict after upgrade.');
      return false;
    }
    if (!result.success) {
      logger.warn('$id: verification failed; upgrade rolled back.');
      return false;
    }
    logger.success('$id $from -> $to');
    for (final migration in migrations) {
      for (final action in migration.actions.whereType<MessageAction>()) {
        logger.info('  ${action.text}');
      }
    }
    return true;
  }
}

final class _Upgrade {
  const _Upgrade({required this.id, required this.from, required this.version});

  final String id;
  final String from;
  final RegistryVersion version;
}
