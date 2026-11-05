import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;

import '../command_context.dart';
import '../infra/exit_codes.dart';
import 'command_helpers.dart';

/// Restores generated extension files from the bundled version.
///
/// ARB files are treated as user content and are preserved unless `--force`.
final class RepairCommand extends KilnCommand {
  RepairCommand(super.context) {
    argParser
      ..addFlag('dry-run', negatable: false)
      ..addFlag('force', negatable: false)
      ..addFlag('yes', abbr: 'y', negatable: false)
      ..addMultiOption('answer', splitCommas: false);
  }

  @override
  String get name => 'repair';

  @override
  String get description =>
      'Restore generated extension files from the bundled version.';

  @override
  String get invocation => 'kiln repair [extension...] [arguments]';

  @override
  Future<int> run() async {
    final project = loadProject();
    final lockStore = LockfileStore(project.root);
    final lockfile = lockStore.read();
    if (lockfile.extensions.isEmpty) {
      logger.info('No extensions are installed.');
      return ExitCodes.success;
    }

    final requested = argResults!.rest.isEmpty
        ? lockfile.extensions.keys.toList(growable: false)
        : argResults!.rest;
    for (final id in requested) {
      if (!lockfile.extensions.containsKey(id)) {
        throw KilnException(
          'Extension "$id" is not installed',
          code: 'repair.not_installed',
          suggestion: 'Run "kiln list --installed" to see installed extensions',
        );
      }
    }

    final force = argResults!['force'] == true;
    final dryRun = argResults!['dry-run'] == true;
    final provided = parseAnswerOptions(
      (argResults!['answer'] as List<String>).cast<String>(),
    );
    const renderer = BrickRenderer();
    const ownership = FileOwnership();
    final changes = <FileChange>[];
    final warnings = <String>[];
    final actions = <_RepairAction>[];
    final updated = <String, LockedExtension>{...lockfile.extensions};

    for (final id in requested) {
      final available = findAvailableExtension(id);
      final locked = lockfile.extensions[id]!;
      if (available == null) {
        warnings.add('$id: manifest is not available; skipped');
        continue;
      }
      if (locked.version != available.manifest.version) {
        warnings.add(
          '$id: installed ${locked.version} does not match bundled '
          '${available.manifest.version}; run "kiln upgrade" first',
        );
        continue;
      }

      final answers = answerForExtension(
        available,
        saved: project.extensionAnswers[id] ?? const <String, Object?>{},
        provided: provided,
        prompter: prompter.withAssumeYes(true),
      );
      final vars = buildTemplateVars(
        extension: available,
        answers: answers,
        project: project.projectForTemplates,
      );
      final rendered = await renderer.render(
        bundle: available.bundle,
        vars: vars,
      );
      final renderedPaths = <String>{};
      final nextFiles = <String, String>{...locked.files};

      for (final file in rendered) {
        final relative = file.relativePath;
        renderedPaths.add(relative);
        final target = File(p.join(project.root.path, relative));
        final desiredHash = ownership.hashBytes(file.bytes);
        final currentHash = target.existsSync()
            ? ownership.hashFile(target)
            : null;
        if (currentHash == desiredHash) {
          nextFiles[relative] = desiredHash;
          continue;
        }
        if (currentHash == null) {
          actions.add(_RepairAction.write(relative, file.bytes));
          changes.add(FileChange(relative, FileChangeKind.create));
          nextFiles[relative] = desiredHash;
          continue;
        }
        if (relative.endsWith('.arb') && !force) {
          warnings.add(
            '$id: preserved edited $relative (use --force to overwrite)',
          );
          changes.add(FileChange(relative, FileChangeKind.skip));
          continue;
        }
        actions.add(_RepairAction.write(relative, file.bytes));
        changes.add(FileChange(relative, FileChangeKind.overwrite));
        nextFiles[relative] = desiredHash;
      }

      for (final relative in locked.files.keys) {
        if (renderedPaths.contains(relative)) {
          continue;
        }
        final target = File(p.join(project.root.path, relative));
        if (!target.existsSync()) {
          nextFiles.remove(relative);
          continue;
        }
        if (relative.endsWith('.arb') && !force) {
          warnings.add(
            '$id: preserved stale $relative (use --force to delete)',
          );
          changes.add(FileChange(relative, FileChangeKind.skip));
          continue;
        }
        final trackedHash = locked.files[relative] ?? '';
        final currentHash = ownership.hashFile(target);
        if (currentHash == trackedHash || force) {
          actions.add(_RepairAction.delete(relative));
          changes.add(FileChange(relative, FileChangeKind.delete));
          nextFiles.remove(relative);
        } else {
          warnings.add('$id: skipped stale $relative because it was edited');
          changes.add(FileChange(relative, FileChangeKind.skip));
        }
      }

      updated[id] = locked.copyWith(files: nextFiles);
    }

    final codegen = const ExtensionsCodegen();
    final codegenFile = codegen.fileIn(project.root);
    final codegenSource = codegen.build(updated.keys);
    final codegenChanged =
        !codegenFile.existsSync() ||
        codegenFile.readAsStringSync() != codegenSource;
    if (codegenChanged) {
      changes.add(
        FileChange(
          ExtensionsCodegen.relativePath,
          codegenFile.existsSync()
              ? FileChangeKind.overwrite
              : FileChangeKind.create,
        ),
      );
    }

    printChanges(logger, changes);
    printWarnings(logger, warnings);
    if (actions.isEmpty && !codegenChanged) {
      logger.success('Nothing to repair.');
      return ExitCodes.success;
    }
    if (dryRun) {
      logger.info('Dry run: no files were written.');
      return ExitCodes.success;
    }
    if (!prompter
        .withAssumeYes(argResults!['yes'] == true)
        .confirm(
          'Apply ${actions.length + (codegenChanged ? 1 : 0)} repair change(s)?',
          defaultValue: false,
        )) {
      logger.info('Cancelled.');
      return ExitCodes.success;
    }

    for (final action in actions) {
      final target = File(p.join(project.root.path, action.path));
      if (action.bytes == null) {
        if (target.existsSync()) {
          target.deleteSync();
        }
        continue;
      }
      target.parent.createSync(recursive: true);
      target.writeAsBytesSync(action.bytes!);
    }
    if (codegenChanged) {
      codegenFile.parent.createSync(recursive: true);
      codegenFile.writeAsStringSync(codegenSource);
      logger.info('  sync       ${ExtensionsCodegen.relativePath}');
    }
    lockStore.write(Lockfile(core: lockfile.core, extensions: updated));
    logger.success(
      'Repaired ${actions.length} file(s) across '
      '${requested.length} extension(s).',
    );
    return ExitCodes.success;
  }
}

final class _RepairAction {
  const _RepairAction._({required this.path, this.bytes});

  factory _RepairAction.write(String path, List<int> bytes) =>
      _RepairAction._(path: path, bytes: bytes);

  factory _RepairAction.delete(String path) => _RepairAction._(path: path);

  final String path;

  /// Null means delete.
  final List<int>? bytes;
}
