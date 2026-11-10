import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../kiln_exception.dart';
import '../manifest/extension_manifest.dart';
import '../migrator/migration.dart';
import '../migrator/migration_actions.dart';
import '../migrator/migration_runner.dart';
import '../renderer/brick_renderer.dart';
import '../renderer/collision_policy.dart';
import '../renderer/hook_policy.dart';
import '../renderer/template_vars.dart';
import '../resolver/dependency_graph.dart';
import '../resolver/extension_resolver.dart';
import '../resolver/resolution_plan.dart';
import 'extensions_codegen.dart';
import 'lockfile.dart';
import 'native/native_setup.dart';
import 'native/patch.dart';
import 'ownership/file_ownership.dart';
import 'ownership/patch_journal.dart';
import 'pubspec_reader.dart';
import 'pubspec_writer.dart';
import 'transaction/root_path.dart';
import 'transaction/transaction.dart';
import 'verification/dry_run_reporter.dart';
import 'verification/verifier.dart';

/// Options for one installation.
final class InstallOptions {
  const InstallOptions({
    this.dryRun = false,
    this.verify = true,
    this.collisionPolicy = CollisionPolicy.skip,
    this.runHooks = false,
    this.approveHooks = false,
  });

  final bool dryRun;
  final bool verify;
  final CollisionPolicy collisionPolicy;
  final bool runHooks;
  final bool approveHooks;
}

/// Result of `kiln add`.
final class InstallResult {
  const InstallResult({
    required this.plan,
    required this.changes,
    required this.patches,
    required this.dependencies,
    required this.devDependencies,
    required this.manualSteps,
    required this.warnings,
    this.dryRun,
    this.verification,
    this.lockfile,
  });

  final ResolutionPlan plan;
  final List<FileChange> changes;
  final List<String> patches;
  final Map<String, Object?> dependencies;
  final Map<String, Object?> devDependencies;
  final List<PlannedManualStep> manualSteps;
  final List<String> warnings;
  final DryRunReport? dryRun;
  final VerificationResult? verification;
  final Lockfile? lockfile;

  bool get hasConflicts =>
      changes.any((change) => change.kind == FileChangeKind.conflict);

  bool get success => !hasConflicts && (verification?.isSuccess ?? true);
}

/// Options for removing one extension.
final class RemoveOptions {
  const RemoveOptions({
    this.dryRun = false,
    this.force = false,
    this.verify = false,
  });

  final bool dryRun;
  final bool force;
  final bool verify;
}

/// Result of `kiln remove`.
final class RemoveResult {
  const RemoveResult({
    required this.id,
    required this.changes,
    required this.deletedFiles,
    required this.skippedFiles,
    required this.revertedPatches,
    required this.removedDependencies,
    required this.warnings,
    this.dryRun,
    this.verification,
  });

  final String id;
  final List<FileChange> changes;
  final List<String> deletedFiles;
  final List<String> skippedFiles;
  final List<String> revertedPatches;
  final List<String> removedDependencies;
  final List<String> warnings;
  final DryRunReport? dryRun;
  final VerificationResult? verification;

  bool get success => verification?.isSuccess ?? true;
}

final class _PlannedFile {
  const _PlannedFile(this.bytes, this.owner);

  final List<int> bytes;
  final String owner;
}

/// Applies extensions to a project through a reversible activeTransaction.
final class ExtensionInstaller {
  ExtensionInstaller({
    required this.projectRoot,
    required this.available,
    this.renderer = const BrickRenderer(),
    this.nativeSetup = const NativeSetup(),
    this.verifier = const Verifier(),
    this.collisionResolver = const CollisionResolver(),
    this.hookPolicy = const HookPolicy(),
  });

  final Directory projectRoot;
  final List<AvailableExtension> available;
  final BrickRenderer renderer;
  final NativeSetup nativeSetup;
  final Verifier verifier;
  final CollisionResolver collisionResolver;
  final HookPolicy hookPolicy;

  Future<InstallResult> add({
    required List<String> requested,
    required Map<String, Object?> project,
    Map<String, Map<String, Object?>> answers =
        const <String, Map<String, Object?>>{},
    InstallOptions options = const InstallOptions(),
    Transaction? transaction,
    Set<String> hostCapabilities = const <String>{},
    Set<String> hostSlots = const <String>{'app.wrappers'},
  }) async {
    final lockStore = LockfileStore(projectRoot);
    final lockfile = lockStore.read();
    final plan = ExtensionResolver(available).resolve(
      installed: lockfile.ids,
      requested: requested.toSet(),
      hostCapabilities: hostCapabilities,
      hostSlots: hostSlots,
    );

    final pubspecFile = File(p.join(projectRoot.path, 'pubspec.yaml'));
    final pubspec = PubspecReader(pubspecFile).read();
    const ownership = FileOwnership();
    final changes = <FileChange>[];
    final plannedFiles = <String, _PlannedFile>{};
    final patchJournal = PatchJournal();
    for (final entry in lockfile.extensions.entries) {
      for (final patchId in entry.value.patches) {
        patchJournal.register(patchId, entry.key);
      }
    }
    final nativeFiles = ProjectFiles(projectRoot);
    final patches = <Patch>[];
    final patchIds = <String>[];
    final dependencies = <String, Object?>{};
    final devDependencies = <String, Object?>{};
    final warnings = <String>[...plan.warnings];
    final newEntries = <String, LockedExtension>{...lockfile.extensions};

    for (final extension in plan.added) {
      final manifest = extension.manifest;
      if (extension.bundle.hooks.isNotEmpty) {
        if (options.runHooks) {
          hookPolicy.ensureCanRun(manifest, userApproved: options.approveHooks);
        } else {
          warnings.add(
            'Extension "${manifest.id}" declares hooks; hooks were skipped',
          );
        }
      }

      final vars = _templateVars(
        extension,
        answers[manifest.id] ?? const <String, Object?>{},
        project,
      );
      final rendered = await renderer.render(
        bundle: extension.bundle,
        vars: vars,
      );
      final filesForLock = <String, String>{};

      void planFile(String relative, List<int> bytes) {
        final target = File(RootPath(projectRoot).resolve(relative));
        final exists = target.existsSync();
        final currentHash = exists ? ownership.hashFile(target) : null;
        final ownedHash = lockfile.extensions[manifest.id]?.files[relative];
        final action = collisionResolver.decide(
          exists: exists,
          currentHash: currentHash,
          ownedHash: ownedHash,
          policy: options.collisionPolicy,
        );

        if (action == CollisionAction.conflict) {
          _recordChange(changes, relative, FileChangeKind.conflict);
          warnings.add(
            'File "$relative" was edited by the user; it was not replaced',
          );
          return;
        }
        if (action == CollisionAction.skip) {
          _recordChange(changes, relative, FileChangeKind.skip);
          return;
        }

        final previous = plannedFiles[relative];
        if (previous != null &&
            !const ListEquality<int>().equals(previous.bytes, bytes)) {
          _recordChange(changes, relative, FileChangeKind.conflict);
          warnings.add(
            'Extensions "${previous.owner}" and "${manifest.id}" render "$relative" differently',
          );
          return;
        }

        plannedFiles[relative] = _PlannedFile(bytes, manifest.id);
        filesForLock[relative] = ownership.hashBytes(bytes);
        _recordChange(
          changes,
          relative,
          action == CollisionAction.create
              ? FileChangeKind.create
              : FileChangeKind.overwrite,
        );
      }

      for (final file in rendered) {
        planFile(file.relativePath, file.bytes);
      }

      // Documentation travels with the code, so an installed app carries its
      // extension docs without visiting the source repository.
      for (final (relative, bytes) in _documentationFiles(extension)) {
        planFile(relative, bytes);
      }

      final native = nativeSetup.plan(
        projectRoot: projectRoot,
        manifest: manifest,
        answers: answers[manifest.id] ?? const <String, Object?>{},
        files: nativeFiles,
      );
      for (final patch in native.patches) {
        patches.add(patch);
        patchIds.add(patch.id);
        patchJournal.register(patch.id, manifest.id);
      }

      _collectDependencies(
        manifest,
        pubspec,
        dependencies,
        devDependencies,
        warnings,
      );

      newEntries[manifest.id] = LockedExtension(
        version: manifest.version,
        source: extension.source,
        dependencies: manifest.dependencies.keys.toList(growable: false),
        devDependencies: manifest.devDependencies.keys.toList(growable: false),
        flutterGenerate: _wantsFlutterGenerate(manifest),
        files: filesForLock,
        patches: native.patches
            .map((patch) => patch.id)
            .toList(growable: false),
        manualSteps: manifest.manualSteps
            .map((step) => step.id)
            .toList(growable: false),
      );
    }

    for (final entry in nativeFiles.changes.entries) {
      final target = File(RootPath(projectRoot).resolve(entry.key));
      if (entry.value == null) {
        if (target.existsSync()) {
          _recordChange(changes, entry.key, FileChangeKind.delete);
        }
        continue;
      }
      final current = target.existsSync() ? target.readAsStringSync() : null;
      if (current == entry.value) {
        continue;
      }
      _recordChange(
        changes,
        entry.key,
        target.existsSync() ? FileChangeKind.overwrite : FileChangeKind.create,
      );
    }

    final pubspecSource = pubspecFile.existsSync()
        ? pubspecFile.readAsStringSync()
        : '';
    var editedPubspec = pubspecSource;
    final pubspecWriter = PubspecWriter(pubspecFile);
    for (final entry in dependencies.entries) {
      editedPubspec = pubspecWriter.editedWithDependencyValue(
        editedPubspec,
        entry.key,
        entry.value,
      );
    }
    for (final entry in devDependencies.entries) {
      editedPubspec = pubspecWriter.editedWithDevDependencyValue(
        editedPubspec,
        entry.key,
        entry.value,
      );
    }
    var ownedGenerate = lockfile.ownedFlutterGenerate;
    if (plan.added.any(
      (extension) => _wantsFlutterGenerate(extension.manifest),
    )) {
      final root = loadYaml(pubspecSource);
      final flutter = root is Map ? root['flutter'] : null;
      if (flutter is! Map || flutter['generate'] != true) {
        ownedGenerate = <String, Object?>{
          'present': flutter is Map && flutter.containsKey('generate'),
          'value': flutter is Map ? flutter['generate'] : null,
        };
      }
      editedPubspec = pubspecWriter.editedWithFlutterGenerate(editedPubspec);
    }
    if (editedPubspec != pubspecSource) {
      _recordChange(changes, 'pubspec.yaml', FileChangeKind.overwrite);
    }

    final newLockfile = Lockfile(
      core: lockfile.core, extensions: newEntries,
      ownedDependencies: {...lockfile.ownedDependencies, ...dependencies},
      ownedDevDependencies: {...lockfile.ownedDevDependencies, ...devDependencies},
      ownedFlutterGenerate: ownedGenerate,
    );
    final codegen = const ExtensionsCodegen();
    final codegenFile = codegen.fileIn(projectRoot);
    final codegenSource = codegen.build(newEntries);
    if (!codegenFile.existsSync()) {
      _recordChange(
        changes,
        ExtensionsCodegen.relativePath,
        FileChangeKind.create,
      );
    } else if (codegenFile.readAsStringSync() != codegenSource) {
      _recordChange(
        changes,
        ExtensionsCodegen.relativePath,
        FileChangeKind.overwrite,
      );
    }

    final lockFile = lockStore.file;
    final lockSource = newLockfile.toYaml();
    if (!lockFile.existsSync() || lockFile.readAsStringSync() != lockSource) {
      _recordChange(
        changes,
        'kiln.lock.yaml',
        lockFile.existsSync()
            ? FileChangeKind.overwrite
            : FileChangeKind.create,
      );
    }

    // Rendered output must not compete with native/configuration writers, nor
    // claim transaction metadata or a parent of another output file.
    for (final path in plannedFiles.keys) {
      if (nativeFiles.changes.containsKey(path) ||
          const {'pubspec.yaml', 'kiln.yaml', 'kiln.lock.yaml', ExtensionsCodegen.relativePath}.contains(path) ||
          path.startsWith('.kiln/') ||
          plannedFiles.keys.any((other) => other != path && other.startsWith('$path/'))) {
        _recordChange(changes, path, FileChangeKind.conflict);
        warnings.add('Multiple output owners for "$path"');
      }
    }
    for (final change in changes) {
      RootPath(projectRoot).resolve(change.path);
    }
    final report = DryRunReport(
      files: List<FileChange>.unmodifiable(changes),
      patches: List<String>.unmodifiable(patchIds),
      dependencies: dependencies,
      devDependencies: devDependencies,
      manualSteps: plan.manualSteps
          .map((step) => step.step.description)
          .toList(growable: false),
      warnings: List<String>.unmodifiable(warnings),
    );

    final hasConflicts = changes.any(
      (change) => change.kind == FileChangeKind.conflict,
    );
    if (options.dryRun || hasConflicts) {
      return InstallResult(
        plan: plan,
        changes: List<FileChange>.unmodifiable(changes),
        patches: List<String>.unmodifiable(patchIds),
        dependencies: dependencies,
        devDependencies: devDependencies,
        manualSteps: plan.manualSteps,
        warnings: List<String>.unmodifiable(warnings),
        dryRun: report,
        lockfile: newLockfile,
      );
    }

    final activeTransaction = transaction ?? Transaction.begin(projectRoot);
    try {
      for (final entry in plannedFiles.entries) {
        activeTransaction.writeFile(entry.key, entry.value.bytes);
      }
      for (final entry in nativeFiles.changes.entries) {
        final content = entry.value;
        if (content == null) {
          activeTransaction.deleteFile(entry.key);
        } else {
          activeTransaction.writeText(entry.key, content);
        }
      }
      if (editedPubspec != pubspecSource) {
        activeTransaction.writeText('pubspec.yaml', editedPubspec);
      }
      activeTransaction.writeText(ExtensionsCodegen.relativePath, codegenSource);
      activeTransaction.writeText('kiln.lock.yaml', lockSource);
      if (transaction == null) activeTransaction.commit();
    } catch (_) {
      if (transaction == null) activeTransaction.rollback();
      rethrow;
    }

    final verification = options.verify
        ? await verifier.verify(projectRoot)
        : null;

    return InstallResult(
      plan: plan,
      changes: List<FileChange>.unmodifiable(changes),
      patches: List<String>.unmodifiable(patchIds),
      dependencies: dependencies,
      devDependencies: devDependencies,
      manualSteps: plan.manualSteps,
      warnings: List<String>.unmodifiable(warnings),
      verification: verification,
      lockfile: newLockfile,
    );
  }

  Future<RemoveResult> remove({
    required String id,
    RemoveOptions options = const RemoveOptions(),
    Transaction? transaction,
    Map<String, Object?> answers = const <String, Object?>{},
  }) async {
    final lockStore = LockfileStore(projectRoot);
    final lockfile = lockStore.read();
    final locked = lockfile.extensions[id];
    if (locked == null) {
      throw KilnException(
        'Extension "$id" is not installed',
        code: 'remove.not_installed',
        suggestion: 'Run "kiln list --installed" to see installed extensions',
      );
    }

    final availableById = <String, AvailableExtension>{
      for (final extension in available) extension.id: extension,
    };
    final installedAvailable = <AvailableExtension>[
      for (final installedId in lockfile.ids)
        if (availableById[installedId] != null) availableById[installedId]!,
    ];
    final dependents = DependencyGraph(installedAvailable).dependentsOf(id);
    final warnings = <String>[];
    if (dependents.isNotEmpty && !options.force) {
      throw KilnException(
        'Cannot remove "$id" while these extensions depend on it: '
        '${dependents.join(', ')}',
        code: 'remove.dependents',
        suggestion:
            'Remove the dependents first, or pass --force to remove anyway',
      );
    }
    if (dependents.isNotEmpty) {
      warnings.add(
        'Removed "$id" while dependents remain: ${dependents.join(', ')}',
      );
    }

    const ownership = FileOwnership();
    final changes = <FileChange>[];
    final deleted = <String>[];
    final skipped = <String>[];
    for (final entry in locked.files.entries) {
      final target = File(RootPath(projectRoot).resolve(entry.key));
      if (!target.existsSync()) {
        skipped.add(entry.key);
        _recordChange(changes, entry.key, FileChangeKind.skip);
        continue;
      }
      final currentHash = ownership.hashFile(target);
      final safeToDelete = entry.value.isNotEmpty && currentHash == entry.value;
      if (!safeToDelete && !options.force) {
        skipped.add(entry.key);
        _recordChange(changes, entry.key, FileChangeKind.skip);
        warnings.add(
          'Skipped "${entry.key}": the file was edited or has no hash',
        );
        continue;
      }
      deleted.add(entry.key);
      if (!safeToDelete) {
        warnings.add(
          'Deleted "${entry.key}" (edited or no hash) because --force was used',
        );
      }
      _recordChange(changes, entry.key, FileChangeKind.delete);
    }

    final manifest = availableById[id]?.manifest;
    final patchJournal = PatchJournal();
    for (final entry in lockfile.extensions.entries) {
      for (final patchId in entry.value.patches) {
        patchJournal.register(patchId, entry.key);
      }
    }
    final patchesToRevert = <Patch>[];
    final reverted = <String>[];
    if (manifest != null) {
      for (final patch in nativeSetup.patchesFor(
        manifest,
        projectRoot,
        answers: answers,
      )) {
        if (!locked.patches.contains(patch.id)) {
          continue;
        }
        final noOwners = patchJournal.unregister(patch.id, id);
        if (noOwners) {
          patchesToRevert.add(patch);
          reverted.add(patch.id);
        }
      }
    } else {
      warnings.add(
        'Manifest for "$id" is not available; native patches were not reverted',
      );
    }
    final nativeFiles = ProjectFiles(projectRoot);
    nativeSetup.revert(
      patches: patchesToRevert,
      projectRoot: projectRoot,
      files: nativeFiles,
    );
    for (final entry in nativeFiles.changes.entries) {
      final target = File(RootPath(projectRoot).resolve(entry.key));
      if (entry.value == null) {
        if (target.existsSync()) {
          _recordChange(changes, entry.key, FileChangeKind.delete);
        }
      } else if (target.existsSync()) {
        if (target.readAsStringSync() != entry.value) {
          _recordChange(changes, entry.key, FileChangeKind.overwrite);
        }
      } else {
        _recordChange(changes, entry.key, FileChangeKind.create);
      }
    }

    final remaining = {...lockfile.extensions}..remove(id);
    final removedDependencies = <String>[];
    final pubspecFile = File(p.join(projectRoot.path, 'pubspec.yaml'));
    final pubspecSource = pubspecFile.existsSync()
        ? pubspecFile.readAsStringSync()
        : '';
    var editedPubspec = pubspecSource;
    final pubspecWriter = PubspecWriter(pubspecFile);
    final pubspec = PubspecReader(pubspecFile).read();
    final ownedDependencies = {...lockfile.ownedDependencies};
    final ownedDevDependencies = {...lockfile.ownedDevDependencies};

    void removeUnneeded(Map<String, Object?> owned, {required bool dev}) {
      final current = dev ? pubspec.devDependencies : pubspec.dependencies;
      for (final entry in owned.entries.toList()) {
        final needed = remaining.values.any((extension) =>
            (dev ? extension.devDependencies : extension.dependencies)
                ?.contains(entry.key) ?? true);
        if (needed) continue;
        // A constraint changed by the user is no longer ours to delete.
        if (current.containsKey(entry.key) &&
            const DeepCollectionEquality().equals(current[entry.key], entry.value)) {
          editedPubspec = dev
              ? pubspecWriter.editedWithoutDevDependency(editedPubspec, entry.key)
              : pubspecWriter.editedWithoutDependency(editedPubspec, entry.key);
          removedDependencies.add(entry.key);
        }
        owned.remove(entry.key);
      }
    }

    removeUnneeded(ownedDependencies, dev: false);
    removeUnneeded(ownedDevDependencies, dev: true);
    var ownedGenerate = lockfile.ownedFlutterGenerate;
    if (ownedGenerate.isNotEmpty &&
        !remaining.values.any((extension) => extension.flutterGenerate != false)) {
      final editor = YamlEditor(editedPubspec);
      final root = loadYaml(editedPubspec);
      final flutter = root is Map ? root['flutter'] : null;
      if (flutter is Map && flutter['generate'] == true) {
        if (ownedGenerate['present'] == true) {
          editor.update(['flutter', 'generate'], ownedGenerate['value']);
        } else {
          editor.remove(['flutter', 'generate']);
        }
        editedPubspec = editor.toString();
      }
      ownedGenerate = const <String, Object?>{};
    }
    final newLockfile = Lockfile(
      core: lockfile.core, extensions: remaining,
      ownedDependencies: ownedDependencies,
      ownedDevDependencies: ownedDevDependencies,
      ownedFlutterGenerate: ownedGenerate,
    );
    if (editedPubspec != pubspecSource) {
      _recordChange(changes, 'pubspec.yaml', FileChangeKind.overwrite);
    }
    final codegen = const ExtensionsCodegen();
    final codegenFile = codegen.fileIn(projectRoot);
    final codegenSource = codegen.build(newLockfile.extensions);
    if (codegenFile.existsSync() &&
        codegenFile.readAsStringSync() != codegenSource) {
      _recordChange(
        changes,
        ExtensionsCodegen.relativePath,
        FileChangeKind.overwrite,
      );
    }
    final lockSource = newLockfile.toYaml();
    if (lockStore.file.existsSync() &&
        lockStore.file.readAsStringSync() != lockSource) {
      _recordChange(changes, 'kiln.lock.yaml', FileChangeKind.overwrite);
    }

    final report = DryRunReport(
      files: List<FileChange>.unmodifiable(changes),
      patches: List<String>.unmodifiable(reverted),
      manualSteps: const <String>[],
      warnings: List<String>.unmodifiable(warnings),
    );
    if (options.dryRun) {
      return RemoveResult(
        id: id,
        changes: List<FileChange>.unmodifiable(changes),
        deletedFiles: List<String>.unmodifiable(deleted),
        skippedFiles: List<String>.unmodifiable(skipped),
        revertedPatches: List<String>.unmodifiable(reverted),
        removedDependencies: List<String>.unmodifiable(removedDependencies),
        warnings: List<String>.unmodifiable(warnings),
        dryRun: report,
      );
    }

    final activeTransaction = transaction ?? Transaction.begin(projectRoot);
    try {
      for (final entry in nativeFiles.changes.entries) {
        final content = entry.value;
        if (content == null) {
          activeTransaction.deleteFile(entry.key);
        } else {
          activeTransaction.writeText(entry.key, content);
        }
      }
      for (final path in deleted) {
        activeTransaction.deleteFile(path);
      }
      if (editedPubspec != pubspecSource) {
        activeTransaction.writeText('pubspec.yaml', editedPubspec);
      }
      activeTransaction.writeText(ExtensionsCodegen.relativePath, codegenSource);
      activeTransaction.writeText('kiln.lock.yaml', lockSource);
      if (transaction == null) activeTransaction.commit();
      _removeEmptiedDirectories(deleted);
    } catch (_) {
      if (transaction == null) activeTransaction.rollback();
      rethrow;
    }

    final verification = options.verify
        ? await verifier.verify(projectRoot)
        : null;

    return RemoveResult(
      id: id,
      changes: List<FileChange>.unmodifiable(changes),
      deletedFiles: List<String>.unmodifiable(deleted),
      skippedFiles: List<String>.unmodifiable(skipped),
      revertedPatches: List<String>.unmodifiable(reverted),
      removedDependencies: List<String>.unmodifiable(removedDependencies),
      warnings: List<String>.unmodifiable(warnings),
      verification: verification,
    );
  }

  /// Stage the entire upgrade before touching the project, then publish its
  /// managed-file delta in one transaction. Verification is inside that same
  /// transaction. The staging transaction is never committed to project history.
  Future<InstallResult> upgrade({
    required String id,
    required Map<String, Object?> project,
    Map<String, Object?> answers = const <String, Object?>{},
    Map<String, Object?> previousAnswers = const <String, Object?>{},
    List<Migration> migrations = const <Migration>[],
    InstallOptions options = const InstallOptions(),
    bool force = false,
    Set<String> hostCapabilities = const <String>{},
    Set<String> hostSlots = const <String>{'app.wrappers'},
  }) async {
    final before = LockfileStore(projectRoot).read();
    final locked = before.extensions[id];
    if (locked == null) {
      throw KilnException('Extension "$id" is not installed', code: 'upgrade.not_installed');
    }
    const MigrationRunner().validate(projectRoot: projectRoot, migrations: migrations);
    final removal = await remove(
      id: id, answers: previousAnswers,
      options: const RemoveOptions(dryRun: true, force: true),
    );
    if (!force) {
      for (final entry in locked.files.entries) {
        final file = File(RootPath(projectRoot).resolve(entry.key));
        if (file.existsSync() &&
            (entry.value.isEmpty || const FileOwnership().hashFile(file) != entry.value)) {
          throw KilnException('Upgrade would replace edited file "${entry.key}"',
              code: 'upgrade.conflict', suggestion: 'Use --force to replace edited files.');
        }
      }
    }
    final stage = await Directory.systemTemp.createTemp('kiln_upgrade_');
    try {
      _copyForUpgrade(projectRoot, stage);
      final stagedTransaction = Transaction.begin(stage);
      final staged = ExtensionInstaller(
        projectRoot: stage, available: available, renderer: renderer,
        nativeSetup: nativeSetup, verifier: verifier,
        collisionResolver: collisionResolver, hookPolicy: hookPolicy,
      );
      // Guard migration destinations too: a rename must not clobber a new user
      // file merely because the migration runs before rendered-file planning.
      for (final migration in migrations) {
        for (final action in migration.actions) {
          if (action is RenameFileAction && !force) {
            final target = File(RootPath(stage).resolve(action.to));
            if (target.existsSync() && !locked.files.containsKey(action.to)) {
              throw KilnException('Migration would overwrite "${action.to}"', code: 'upgrade.conflict');
            }
          }
        }
      }
      const MigrationRunner().run(
        projectRoot: stage, migrations: migrations, transaction: stagedTransaction,
      );
      await staged.remove(
        id: id, answers: previousAnswers, transaction: stagedTransaction,
        options: const RemoveOptions(force: true),
      );
      final result = await staged.add(
        requested: [id], project: project, answers: {id: answers},
        hostCapabilities: hostCapabilities, hostSlots: hostSlots,
        transaction: stagedTransaction,
        options: InstallOptions(
          verify: false, collisionPolicy: force ? CollisionPolicy.overwrite : CollisionPolicy.ask,
          runHooks: options.runHooks, approveHooks: options.approveHooks,
        ),
      );
      if (result.hasConflicts) return result;
      final config = File(RootPath(stage).resolve('kiln.yaml'));
      if (config.existsSync()) {
        final editor = YamlEditor(config.readAsStringSync());
        final root = editor.parseAt([]);
        if (root is! YamlMap) {
          throw const KilnException('kiln.yaml must be a map', code: 'upgrade.config_invalid');
        }
        if (!root.containsKey('extensions')) editor.update(['extensions'], <String, Object?>{});
        editor.update(['extensions', id], answers);
        stagedTransaction.writeText('kiln.yaml', editor.toString());
      }
      final paths = stagedTransaction.journal.operations.map((op) => op.path).toSet();
      for (final path in paths) {
        RootPath(projectRoot).resolve(path);
        RootPath(stage).resolve(path);
      }
      if (options.dryRun) return result;
      final transaction = Transaction.begin(projectRoot);
      VerificationResult? verification;
      try {
        // Include unchanged managed files and pub's lock in the verifier snapshot.
        for (final path in {
          ...paths, 'pubspec.lock',
          for (final extension in before.extensions.values) ...extension.files.keys,
        }) {
          transaction.capture(path);
        }
        for (final path in paths) {
          final file = File(RootPath(stage).resolve(path));
          if (file.existsSync()) {
            transaction.writeFile(path, file.readAsBytesSync());
          } else {
            transaction.deleteFile(path);
          }
        }
        verification = options.verify ? await verifier.verify(projectRoot) : null;
        if (verification != null && !verification.isSuccess) {
          transaction.rollback();
        } else {
          transaction.commit();
          _removeEmptiedDirectories(removal.deletedFiles);
        }
      } catch (_) {
        transaction.rollback();
        rethrow;
      }
      return InstallResult(
        plan: result.plan, changes: result.changes, patches: result.patches,
        dependencies: result.dependencies, devDependencies: result.devDependencies,
        manualSteps: result.manualSteps, warnings: result.warnings,
        verification: verification, lockfile: result.lockfile,
      );
    } finally {
      await stage.delete(recursive: true);
    }
  }

  void _copyForUpgrade(Directory source, Directory destination, [String prefix = '']) {
    for (final entity in source.listSync(followLinks: false)) {
      final relative = '$prefix${p.basename(entity.path)}';
      if (const {'.git', '.dart_tool', 'build', '.kiln/backups', '.kiln/journal'}.contains(relative)) continue;
      RootPath(projectRoot).resolve(relative);
      final target = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) {
        final directory = Directory(target)..createSync();
        _copyForUpgrade(entity, directory, '$relative/');
      } else if (entity is File) {
        entity.copySync(target);
      }
    }
  }

  /// Deletes directories that [deletedPaths] emptied, bottom-up.
  ///
  /// A state extension owns a deep feature tree, so removing it would leave
  /// folders such as `lib/features/notes/presentation/bloc` behind forever.
  /// Only directories that are now empty and deeper than the shared template
  /// layout are removed, so a folder the application may still use stays.
  void _removeEmptiedDirectories(List<String> deletedPaths) {
    final candidates = <String>{};
    for (final path in deletedPaths) {
      var parent = p.posix.dirname(_posix(path));
      while (p.posix.split(parent).length >= 3) {
        candidates.add(parent);
        parent = p.posix.dirname(parent);
      }
    }

    final deepestFirst = candidates.toList()
      ..sort(
        (left, right) => p.posix
            .split(right)
            .length
            .compareTo(p.posix.split(left).length),
      );
    for (final relative in deepestFirst) {
      final directory = Directory(RootPath(projectRoot).resolve(relative));
      if (!directory.existsSync()) {
        continue;
      }
      if (directory.listSync().isEmpty) {
        directory.deleteSync();
      }
    }
  }

  /// Documentation files for [extension], as `(app-relative path, bytes)`
  /// pairs installed under `lib/extensions/<id>/`. Bundled extensions carry
  /// the bytes in [AvailableExtension.docs]; store extensions are read
  /// verbatim from the extension root. Copied raw, never templated.
  List<(String, List<int>)> _documentationFiles(AvailableExtension extension) {
    final id = extension.id;
    final embedded = extension.docs;
    if (embedded.isNotEmpty) {
      return <(String, List<int>)>[
        for (final entry in embedded.entries)
          ('lib/extensions/$id/${_posix(entry.key)}', entry.value),
      ];
    }
    final root = extension.manifest.rootPath;
    if (root == null) {
      return const <(String, List<int>)>[];
    }
    final files = <(String, List<int>)>[];
    final readme = File(p.join(root, 'README.md'));
    if (readme.existsSync()) {
      files.add((
        'lib/extensions/$id/README.md',
        readme.readAsBytesSync(),
      ));
    }
    final docs = Directory(p.join(root, 'docs'));
    if (!docs.existsSync()) {
      return files;
    }
    final docFiles =
        docs.listSync(recursive: true).whereType<File>().toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    for (final doc in docFiles) {
      final relative = p.relative(doc.path, from: root).replaceAll('\\', '/');
      files.add(('lib/extensions/$id/$relative', doc.readAsBytesSync()));
    }
    return files;
  }

  bool _wantsFlutterGenerate(ExtensionManifest manifest) {
    final flutter = manifest.raw['flutter'];
    return flutter is Map && flutter['generate'] == true;
  }

  Map<String, dynamic> _templateVars(
    AvailableExtension extension,
    Map<String, Object?> answers,
    Map<String, Object?> project,
  ) {
    try {
      return buildTemplateVars(
        extension: extension,
        answers: answers,
        project: project,
      );
    } on PromptAnswerException catch (error) {
      throw KilnException(
        error.toString(),
        code: 'prompt.invalid',
        suggestion: 'Pass the value with --answer ${error.prompt.name}=<value>',
      );
    }
  }

  void _collectDependencies(
    ExtensionManifest manifest,
    PubspecInfo pubspec,
    Map<String, Object?> dependencies,
    Map<String, Object?> devDependencies,
    List<String> warnings,
  ) {
    for (final entry in manifest.dependencies.entries) {
      final existing = pubspec.dependencies[entry.key];
      if (!pubspec.hasDependency(entry.key)) {
        dependencies[entry.key] = entry.value;
      } else if (existing != entry.value) {
        warnings.add(
          'Dependency "${entry.key}" already exists as "$existing"; left unchanged',
        );
      }
    }
    for (final entry in manifest.devDependencies.entries) {
      final existing = pubspec.devDependencies[entry.key];
      if (!pubspec.hasDevDependency(entry.key)) {
        devDependencies[entry.key] = entry.value;
      } else if (existing != entry.value) {
        warnings.add(
          'Dev dependency "${entry.key}" already exists as "$existing"; left unchanged',
        );
      }
    }
  }

  void _recordChange(
    List<FileChange> changes,
    String path,
    FileChangeKind kind,
  ) {
    final index = changes.indexWhere((change) => change.path == path);
    if (index < 0) {
      changes.add(FileChange(path, kind));
      return;
    }
    if (changes[index].kind == FileChangeKind.conflict) {
      return;
    }
    changes[index] = FileChange(path, kind);
  }
}

String _posix(String value) => p.posix.normalize(value.replaceAll('\\', '/'));
