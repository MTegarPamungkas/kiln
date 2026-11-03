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
import 'store_view.dart';

/// Searches and installs extensions from a configured registry.
final class StoreCommand extends KilnCommand {
  StoreCommand(super.context) {
    argParser
      ..addOption('version')
      ..addMultiOption('answer', splitCommas: false)
      ..addFlag('yes', abbr: 'y', negatable: false)
      ..addFlag('dry-run', negatable: false)
      ..addFlag('force', negatable: false)
      ..addFlag('no-verify', negatable: false)
      ..addFlag('run-hooks', negatable: false)
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'store';

  @override
  String get description => 'Search and install extensions from the registry.';

  @override
  String get invocation => 'kiln store [search|info|install] [query]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final action = rest.isEmpty ? 'search' : rest.first;
    final query = rest.length > 1 ? rest[1] : '';
    final project = optionalProject;
    final support = RegistrySupport.from(
      context,
      projectConfig: project?.config,
    );

    if (action == 'install') {
      if (query.isEmpty) {
        usageException('kiln store install <extension>');
      }
      if (project == null) {
        throw const KilnException(
          'Run this command inside a Kiln project folder.',
          code: 'project.not_found',
        );
      }
      if (support == null) {
        throw const KilnException(
          'Registry is not configured.',
          code: 'store.not_configured',
          suggestion: 'Run kiln config --registry=<path|url>',
        );
      }
      return _install(project, support, query);
    }

    if (action == 'info') {
      if (query.isEmpty) {
        usageException('kiln store info <extension>');
      }
      if (support != null) {
        final index = await _indexOrNull(support);
        final extension = index?.find(query);
        if (extension != null) {
          return _printRegistryInfo(extension);
        }
      }
      return _printBundledInfo(query);
    }

    final term = action == 'search' ? query : action;
    if (support != null) {
      final index = await _indexOrNull(support);
      if (index != null) {
        return _printRegistrySearch(SearchIndex(index).search(term), term);
      }
    }
    return _printBundledSearch(term);
  }

  Future<RegistryIndex?> _indexOrNull(RegistrySupport support) async {
    try {
      return await support.index();
    } on Object catch (error) {
      logger.warn('Cannot read the registry: $error');
      return null;
    }
  }

  int _printRegistryInfo(RegistryExtension extension) {
    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(extension.toJson());
    } else {
      final installed = _installedVersion(extension.id);
      final info = StoreInfo(
        title: extension.name,
        subtitle:
            '${extension.id} · ${extension.latest} · ${extension.tier.name}',
        description: extension.description,
        fields: <(String, String)>[
          ('ID', extension.id),
          ('Latest', extension.latest),
          ('Tier', extension.tier.name),
          ('Category', extension.category),
          ('Installed', installed ?? 'not installed'),
        ],
        sections: <StoreSection>[
          StoreSection(
            'Versions',
            extension.versions
                .map(
                  (version) =>
                      '${version.version}  ${_shortSha(version.sha256)}'
                      '${version.provides.isEmpty ? '' : '  provides: ${version.provides.join(', ')}'}'
                      '${version.requires.isEmpty ? '' : '  requires: ${version.requires.join(', ')}'}',
                )
                .toList(growable: false),
          ),
        ],
      );
      for (final line in renderStoreInfo(info)) {
        logger.info(line);
      }
    }
    return ExitCodes.success;
  }

  int _printRegistrySearch(List<RegistryExtension> matches, String term) {
    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'query': term,
        'results': matches.map((item) => item.toJson()).toList(),
      });
    } else {
      final rows = matches
          .map(
            (item) => StoreRow(
              id: item.id,
              version: item.latest,
              tier: item.tier.name,
              category: item.category,
              description: item.description,
              status: _statusFor(item.id, item.latest),
            ),
          )
          .toList(growable: false);
      for (final line in renderStoreSearch(rows, term)) {
        logger.info(line);
      }
    }
    return ExitCodes.success;
  }

  int _printBundledInfo(String id) {
    final extension = findAvailableExtension(id);
    if (extension == null) {
      throw KilnException('Extension "$id" not found', code: 'catalog.missing');
    }
    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(extension.manifest.toJson());
    } else {
      final manifest = extension.manifest;
      final installed = _installedVersion(extension.id);
      final info = StoreInfo(
        title: manifest.name,
        subtitle:
            '${manifest.id} · ${manifest.version} · ${manifest.tier.name}',
        description: manifest.description,
        fields: <(String, String)>[
          ('ID', manifest.id),
          ('Version', manifest.version),
          ('Tier', manifest.tier.name),
          ('Category', manifest.category),
          ('Installed', installed ?? 'not installed'),
          if (manifest.provides.isNotEmpty)
            ('Capabilities', manifest.provides.join(', ')),
          if (manifest.requires.isNotEmpty)
            ('Requires', manifest.requires.join(', ')),
          if (manifest.platformSetup.platforms.isNotEmpty)
            ('Platforms', manifest.platformSetup.platforms.join(', ')),
          if (manifest.dependencies.isNotEmpty)
            (
              'Dependencies',
              manifest.dependencies.entries
                  .map((entry) => '${entry.key} ${entry.value}')
                  .join(', '),
            ),
        ],
        sections: <StoreSection>[
          if (manifest.prompts.isNotEmpty)
            StoreSection(
              'Prompts',
              manifest.prompts.map(_promptLine).toList(growable: false),
            ),
          StoreSection('Bundled version', <String>[manifest.version]),
        ],
      );
      for (final line in renderStoreInfo(info)) {
        logger.info(line);
      }
    }
    return ExitCodes.success;
  }

  int _printBundledSearch(String term) {
    final matches = extensionCatalog
        .where((extension) {
          if (term.isEmpty) {
            return true;
          }
          final needle = term.toLowerCase();
          return extension.id.contains(needle) ||
              extension.manifest.name.toLowerCase().contains(needle) ||
              extension.manifest.category.contains(needle) ||
              extension.manifest.description.toLowerCase().contains(needle);
        })
        .toList(growable: false);
    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'query': term,
        'results': matches
            .map(
              (extension) => <String, Object?>{
                'id': extension.id,
                'name': extension.manifest.name,
                'version': extension.manifest.version,
                'category': extension.manifest.category,
                'description': extension.manifest.description,
              },
            )
            .toList(),
      });
    } else {
      final rows = matches
          .map(
            (extension) => StoreRow(
              id: extension.id,
              version: extension.manifest.version,
              tier: extension.manifest.tier.name,
              category: extension.manifest.category,
              description: extension.manifest.description,
              status: _statusFor(extension.id, extension.manifest.version),
            ),
          )
          .toList(growable: false);
      for (final line in renderStoreSearch(rows, term)) {
        logger.info(line);
      }
    }
    return ExitCodes.success;
  }

  String? _installedVersion(String id) =>
      optionalProject?.lockfile.extensions[id]?.version;

  String _statusFor(String id, String latest) {
    final installed = _installedVersion(id);
    if (installed == null) {
      return '-';
    }
    return installed == latest ? 'installed' : 'update';
  }

  String _shortSha(String sha) {
    final value = sha.startsWith('sha256:') ? sha.substring(7) : sha;
    return value.length <= 12 ? value : '${value.substring(0, 12)}...';
  }

  String _promptLine(PromptSpec prompt) {
    final defaultValue = prompt.defaultValue;
    final defaultText = defaultValue == null || '$defaultValue'.isEmpty
        ? ''
        : ', default: $defaultValue';
    final label = prompt.label ?? prompt.description ?? '';
    final suffix = label.isEmpty ? '' : '  $label';
    return '${prompt.name} (${_promptTypeName(prompt.type)}'
        '${prompt.required ? ', required' : ''}$defaultText)$suffix';
  }

  String _promptTypeName(PromptType type) {
    return switch (type) {
      PromptType.intValue => 'int',
      PromptType.boolValue => 'bool',
      PromptType.enumValue => 'enum',
      _ => type.name,
    };
  }

  Future<int> _install(
    ProjectContext project,
    RegistrySupport support,
    String id,
  ) async {
    final index = await support.index();
    final extension = index.find(id);
    if (extension == null) {
      throw KilnException(
        'Extension "$id" is not in the registry.',
        code: 'store.missing',
      );
    }

    final requestedVersion = argResults!['version'] as String?;
    final version = requestedVersion == null
        ? VersionResolver().resolve(
            extension,
            kilnVersion: Version.parse(project.lockfile.core),
          )
        : extension.findVersion(requestedVersion);
    if (version == null) {
      throw KilnException(
        requestedVersion == null
            ? 'No compatible version of extension "$id" was found.'
            : 'Version $requestedVersion of extension "$id" was not found.',
        code: 'store.version_missing',
      );
    }

    final package = await support.fetch(id, version);
    try {
      final hooks = Directory(p.join(package.directory.path, 'brick', 'hooks'))
          .existsSync();
      final decision = const TrustPolicy().evaluate(
        package.available.manifest,
        hasHooks: hooks,
      );
      if (!decision.allowed) {
        throw KilnException(
          'Extension "$id" is not allowed: ${decision.reason}',
          code: 'store.untrusted',
        );
      }
      final runHooks = argResults!['run-hooks'] == true;
      if (decision.requiresConfirmation &&
          !prompter
              .withAssumeYes(argResults!['yes'] == true)
              .confirm(decision.reason, defaultValue: false)) {
        logger.info('Instalasi dibatalkan.');
        return ExitCodes.success;
      }
      if (runHooks && argResults!['yes'] != true && !prompter.interactive) {
        throw const KilnException(
          'Hooks require interactive confirmation or --yes.',
          code: 'store.hook_confirmation',
        );
      }

      final available = package.available;
      if (argResults!['dry-run'] != true) {
        logger.info(
          'Installing ${available.manifest.name} '
          '(${available.manifest.id}) ${available.manifest.version}',
        );
        logger.blank();
      }
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
        available: <AvailableExtension>[available],
      );
      final result = await installer.add(
        requested: <String>[id],
        project: project.projectForTemplates,
        answers: <String, Map<String, Object?>>{id: answers},
        options: InstallOptions(
          dryRun: argResults!['dry-run'] == true,
          verify: argResults!['no-verify'] != true,
          collisionPolicy: argResults!['force'] == true
              ? CollisionPolicy.overwrite
              : CollisionPolicy.ask,
          runHooks: runHooks,
          approveHooks: argResults!['yes'] == true && runHooks,
        ),
        hostCapabilities: const <String>{'app_basic'},
      );

      if (argResults!['json'] == true) {
        JsonReporter(logger.raw).write(<String, Object?>{
          'id': id,
          'version': available.manifest.version,
          'changes': result.changes.map((change) => change.toJson()).toList(),
          'patches': result.patches,
          'warnings': result.warnings,
          'dry_run': result.dryRun?.toJson(),
        });
      } else if (result.dryRun != null) {
        logger.info(result.dryRun!.toText());
      } else {
        printChanges(logger, result.changes);
        printWarnings(logger, result.warnings);
        printManualSteps(logger, result.manualSteps);
      }
      if (result.hasConflicts) {
        return ExitCodes.conflict;
      }
      if (argResults!['dry-run'] != true) {
        project.updateExtensionAnswers(id, answers);
        logger.success('Installed $id ${available.manifest.version}');
      }
      if (result.verification != null && !result.verification!.isSuccess) {
        logger.error('Verification failed.');
        logger.info(result.verification!.output);
        return ExitCodes.verification;
      }
      return ExitCodes.success;
    } finally {
      await package.dispose();
    }
  }
}
