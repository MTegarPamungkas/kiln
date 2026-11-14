import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
import '../project_context.dart';
import '../version.dart';
import 'command_helpers.dart';

enum DoctorStatus { ok, warn, fail }

final class DoctorCheck {
  const DoctorCheck({
    required this.id,
    required this.status,
    required this.message,
    this.suggestion,
  });

  final String id;
  final DoctorStatus status;
  final String message;
  final String? suggestion;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'status': status.name,
    'message': message,
    if (suggestion != null) 'suggestion': suggestion,
  };
}

/// Checks project health and can regenerate owned files.
final class DoctorCommand extends KilnCommand {
  DoctorCommand(super.context) {
    argParser
      ..addFlag('fix', negatable: false)
      ..addFlag('json', negatable: false);
  }

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check project health and optionally fix it.';

  @override
  Future<int> run() async {
    final project = loadProject();
    final fix = argResults!['fix'] == true;
    final checks = <DoctorCheck>[];
    final ownership = const FileOwnership();

    final codegen = const ExtensionsCodegen();
    final codegenFile = codegen.fileIn(project.root);
    final expectedCodegen = codegen.build(project.lockfile.extensions);
    if (!codegenFile.existsSync()) {
      if (fix) {
        fileSystem.writeAsString(codegenFile.path, expectedCodegen);
        checks.add(
          const DoctorCheck(
            id: 'codegen',
            status: DoctorStatus.ok,
            message: 'extensions.g.dart regenerated',
          ),
        );
      } else {
        checks.add(
          const DoctorCheck(
            id: 'codegen',
            status: DoctorStatus.fail,
            message: 'lib/extensions/extensions.g.dart is missing',
            suggestion: 'Run kiln doctor --fix',
          ),
        );
      }
    } else if (codegenFile.readAsStringSync() != expectedCodegen) {
      if (fix) {
        fileSystem.writeAsString(codegenFile.path, expectedCodegen);
        checks.add(
          const DoctorCheck(
            id: 'codegen',
            status: DoctorStatus.ok,
            message: 'extensions.g.dart synchronized with the lockfile',
          ),
        );
      } else {
        checks.add(
          const DoctorCheck(
            id: 'codegen',
            status: DoctorStatus.fail,
            message: 'extensions.g.dart is out of sync with the lockfile',
            suggestion: 'Run kiln doctor --fix',
          ),
        );
      }
    } else {
      checks.add(
        const DoctorCheck(
          id: 'codegen',
          status: DoctorStatus.ok,
          message: 'extensions.g.dart is in sync',
        ),
      );
    }

    final interrupted = const Rollback().latestInterrupted(project.root);
    checks.add(
      DoctorCheck(
        id: 'journal',
        status: interrupted == null ? DoctorStatus.ok : DoctorStatus.fail,
        message: interrupted == null
            ? 'No interrupted operations'
            : 'Interrupted operation found in the journal (${interrupted.id})',
        suggestion: interrupted == null ? null : 'Run kiln rollback',
      ),
    );

    final providedCapabilities = <String>{};
    for (final entry in project.lockfile.extensions.entries) {
      final id = entry.key;
      final locked = entry.value;
      final available = findAvailableExtension(id);
      if (available == null) {
        checks.add(
          DoctorCheck(
            id: 'extension.$id',
            status: DoctorStatus.warn,
            message: 'Manifest $id is missing from the bundled catalog',
          ),
        );
        continue;
      }
      final manifest = available.manifest;
      providedCapabilities.addAll(manifest.provides);

      for (final fileEntry in locked.files.entries) {
        final target = File(p.join(project.root.path, fileEntry.key));
        if (!target.existsSync()) {
          checks.add(
            DoctorCheck(
              id: 'file.$id.${fileEntry.key}',
              status: DoctorStatus.fail,
              message: '$id is missing ${fileEntry.key}',
              suggestion: 'Reinstall the extension or restore the file',
            ),
          );
          continue;
        }
        if (fileEntry.value.isEmpty) {
          checks.add(
            DoctorCheck(
              id: 'hash.$id.${fileEntry.key}',
              status: DoctorStatus.warn,
              message: 'Hash ${fileEntry.key} is unknown',
            ),
          );
          continue;
        }
        if (ownership.hashFile(target) != fileEntry.value) {
          checks.add(
            DoctorCheck(
              id: 'hash.$id.${fileEntry.key}',
              status: DoctorStatus.warn,
              message: 'File ${fileEntry.key} was edited by the user',
            ),
          );
        }
      }

      for (final dependency in manifest.dependencies.keys) {
        if (!project.pubspec.hasDependency(dependency)) {
          checks.add(
            DoctorCheck(
              id: 'dependency.$id.$dependency',
              status: DoctorStatus.fail,
              message: '$id is missing the $dependency dependency',
              suggestion: 'Run flutter pub add $dependency',
            ),
          );
        }
      }

      final extensionPlatforms = manifest.platformSetup.platforms;
      final supportedOnAny =
          extensionPlatforms.isEmpty ||
          project.platforms.any(extensionPlatforms.contains);
      for (final platform in project.platforms) {
        if (!manifest.platformSetup.supports(platform)) {
          checks.add(
            DoctorCheck(
              id: 'platform.$id.$platform',
              status: supportedOnAny ? DoctorStatus.warn : DoctorStatus.fail,
              message: supportedOnAny
                  ? '$id is disabled on $platform'
                  : '$id does not support any project platform',
              suggestion: supportedOnAny
                  ? 'The module is skipped on $platform; other platforms keep working.'
                  : 'Remove $id or add one of: ${extensionPlatforms.join(', ')}',
            ),
          );
        }
      }

      final compatibility = manifest.compatibility.problems(
        kilnVersion: kilnVersion,
        dartVersion: Platform.version.split(' ').first,
      );
      for (final problem in compatibility) {
        checks.add(
          DoctorCheck(
            id: 'compatibility.$id',
            status: DoctorStatus.warn,
            message: '$id: $problem',
          ),
        );
      }
    }

    final layerSources = readLibSources(project.root);
    checks.add(
      capabilityCoverageCheck(
        sourcesByPath: layerSources,
        providedCapabilities: providedCapabilities,
      ),
    );
    if (layerSources.isNotEmpty) {
      for (final violation in layerViolations(
        sourcesByPath: layerSources,
        packageName: project.appName,
      )) {
        checks.add(
          DoctorCheck(
            id: 'layer.${violation.relativePath}',
            status: DoctorStatus.warn,
            message: '${violation.relativePath}: ${violation.message}',
            suggestion: 'Follow the dependency rule in ARCHITECTURE.md.',
          ),
        );
      }
    }

    checks.add(_coreSourceCheck(project));

    final failCount = checks
        .where((check) => check.status == DoctorStatus.fail)
        .length;
    if (argResults!['json'] == true) {
      JsonReporter(logger.raw).write(<String, Object?>{
        'ok': failCount == 0,
        'checks': checks.map((check) => check.toJson()).toList(),
      });
    } else {
      for (final check in checks) {
        final label = switch (check.status) {
          DoctorStatus.ok => '[ok]  ',
          DoctorStatus.warn => '[warn]',
          DoctorStatus.fail => '[fail]',
        };
        logger.info('$label ${check.message}');
        if (check.suggestion != null) {
          logger.info('       ${check.suggestion}');
        }
      }
      if (failCount == 0) {
        logger.success('Project is healthy');
      } else {
        logger.error('$failCount issues need to be fixed');
      }
    }
    return failCount == 0 ? ExitCodes.success : ExitCodes.project;
  }

  /// Reports how `kiln_core` resolves, so a project that only builds on one
  /// machine is visible before it is shared.
  DoctorCheck _coreSourceCheck(ProjectContext project) {
    const id = 'core.source';
    switch (project.pubspec.dependencySource('kiln_core')) {
      case null:
        return const DoctorCheck(
          id: id,
          status: DoctorStatus.fail,
          message: 'kiln_core is not a dependency',
          suggestion: 'Add it with kiln create --core-git <url>',
        );
      case 'git':
        final ref = project.pubspec.gitRef('kiln_core');
        if (ref == null) {
          return const DoctorCheck(
            id: id,
            status: DoctorStatus.warn,
            message:
                'kiln_core resolves from git but tracks the default branch',
            suggestion:
                'Pin a branch, tag, or commit with a git ref so every machine '
                'and CI resolves the same SDK revision.',
          );
        }
        return DoctorCheck(
          id: id,
          status: DoctorStatus.ok,
          message: 'kiln_core resolves from git at $ref',
        );
      case 'path':
        return const DoctorCheck(
          id: id,
          status: DoctorStatus.warn,
          message:
              'kiln_core resolves from a local path, so this project only '
              'builds on a machine that has that checkout',
          suggestion:
              'Replace the path dependency with a git dependency so anyone '
              'with access to the repository can build it, or keep the path on '
              'purpose for local development.',
        );
      case 'hosted':
        return const DoctorCheck(
          id: id,
          status: DoctorStatus.warn,
          message:
              'kiln_core asks pub.dev for a release, but no release is '
              'published there',
          suggestion:
              'Resolve it from the repository with a git dependency, or from a '
              'local checkout with a path dependency.',
        );
      default:
        return const DoctorCheck(
          id: id,
          status: DoctorStatus.fail,
          message: 'kiln_core resolves from an unsupported source',
          suggestion: 'Use a git or path dependency for kiln_core.',
        );
    }
  }
}

/// Contract type names feature code can reference, mapped to the capability
/// id an installed extension must provide for the usage to resolve.
const Map<String, String> _capabilityByContractType = <String, String>{
  'AuthRepository': 'auth',
  'SocialAuth': 'social_auth',
  'RemoteDatabase': 'remote_database',
  'PaginatedRemoteDatabase': 'remote_database',
  'BatchRemoteDatabase': 'remote_database',
  'FileStorage': 'file_storage',
  'CloudFunctions': 'functions',
  'TokenProvider': 'token_provider',
  'AccountManagement': 'account_management',
  'PushTargets': 'push_targets',
};

/// Warns when feature code references a backend capability that no installed
/// extension provides — the situation a backend swap produces for
/// backend-specific capabilities such as `functions`.
DoctorCheck capabilityCoverageCheck({
  required Map<String, String> sourcesByPath,
  required Set<String> providedCapabilities,
}) {
  final typeNames = _capabilityByContractType.keys.toList()..sort();
  final pattern = RegExp('\\b(${typeNames.join('|')})\\b');
  final used = <String>{};
  for (final entry in sourcesByPath.entries) {
    // Extension-owned files implement what their extension provides; only
    // application-owned code decides whether a capability is required.
    if (entry.key.startsWith('lib/extensions/')) {
      continue;
    }
    for (final match in pattern.allMatches(entry.value)) {
      used.add(_capabilityByContractType[match.group(0)]!);
    }
  }
  if (used.isEmpty) {
    return const DoctorCheck(
      id: 'capability.coverage',
      status: DoctorStatus.ok,
      message: 'No backend capability usage in feature code',
    );
  }
  final usedList = used.toList()..sort();
  final missing = used.difference(providedCapabilities).toList()..sort();
  if (missing.isEmpty) {
    return DoctorCheck(
      id: 'capability.coverage',
      status: DoctorStatus.ok,
      message: 'Feature code uses ${usedList.join(', ')}; every capability is '
          'provided by the installed extensions',
    );
  }
  return DoctorCheck(
    id: 'capability.coverage',
    status: DoctorStatus.warn,
    message: 'Feature code uses ${missing.join(', ')}, which no installed '
        'extension provides',
    suggestion: 'Swap to a backend that provides the capability, keep the '
        'usage behind a capability check, or remove the usage',
  );
}
