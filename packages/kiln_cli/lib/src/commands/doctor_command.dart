import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

import '../command_context.dart';
import '../infra/exit_codes.dart';
import '../infra/json_reporter.dart';
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
    final expectedCodegen = codegen.build(project.lockfile.ids);
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

      for (final fileEntry in locked.files.entries) {
        final target = File(p.join(project.root.path, fileEntry.key));
        if (!target.existsSync()) {
          checks.add(
            DoctorCheck(
              id: 'file.$id.${fileEntry.key}',
              status: DoctorStatus.fail,
              message: 'File milik $id hilang: ${fileEntry.key}',
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
              message: '$id membutuhkan dependency $dependency',
              suggestion: 'Run flutter pub add $dependency',
            ),
          );
        }
      }

      for (final platform in project.platforms) {
        if (!manifest.platformSetup.supports(platform)) {
          checks.add(
            DoctorCheck(
              id: 'platform.$id.$platform',
              status: DoctorStatus.fail,
              message: '$id does not support platform $platform',
              suggestion: 'Remove that platform from kiln.yaml',
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
        logger.error('$failCount masalah perlu diperbaiki');
      }
    }
    return failCount == 0 ? ExitCodes.success : ExitCodes.project;
  }
}
