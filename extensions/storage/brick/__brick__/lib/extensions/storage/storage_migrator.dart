import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

typedef StorageMigration = Future<void> Function(Storage storage);

/// Runs storage schema migrations in order.
///
/// Each step snapshots storage, records a checkpoint before the callback runs,
/// and compensates both callback and version-write failures. A checkpoint left
/// behind by a process death is used on the next run to restore the storage to
/// the state before the interrupted step, so a half-applied step is never kept.
/// A checkpoint whose version already reached its target means the step
/// completed and the checkpoint was simply not cleared; it is then discarded
/// without restoring anything.
///
/// Runs sharing the same storage object are serialized in this isolate. Pass a
/// [MutationLock] when another isolate, engine or process can migrate the same
/// storage concurrently. This is still not a database transaction: unrelated
/// writers must not mutate storage during migration, and restoring a checkpoint
/// also reverts keys written by such a writer inside the migration window.
final class StorageMigrator {
  StorageMigrator({
    required this.storage,
    required this.targetVersion,
    this.migrations = const <StorageMigration>[],
    this.versionKey = 'schema_version',
    this.checkpointKey = '__kiln_migration_checkpoint',
    this.lock,
  });

  final Storage storage;
  final int targetVersion;
  final List<StorageMigration> migrations;
  final String versionKey;

  /// Key holding the last step's recovery checkpoint.
  final String checkpointKey;

  /// Optional cross-handle/process exclusion held for a whole migration.
  final MutationLock? lock;

  static final Expando<Future<void>> _tails = Expando<Future<void>>();

  Future<int> run() {
    final result = (_tails[storage] ?? Future<void>.value()).then((_) {
      final guard = lock;
      return guard == null ? _migrate() : guard.runExclusive(_migrate);
    });
    _tails[storage] = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<int> _migrate() async {
    await _recoverInterruptedStep();
    final raw = await storage.read(versionKey);
    final current = int.tryParse(raw ?? '') ?? 0;
    if (current >= targetVersion) {
      return current;
    }
    for (var version = current; version < targetVersion; version++) {
      if (version >= migrations.length) {
        throw Failure(
          code: FailureCode.unexpected,
          message:
              'No storage migration is registered for schema version '
              '${version + 1}.',
          kind: FailureKind.unknown,
          details: <String, Object?>{'from': version, 'target': targetVersion},
        );
      }
      await _runStep(migrations[version], version);
    }
    return targetVersion;
  }

  /// Rolls back a step that a previous process started but never finished.
  Future<void> _recoverInterruptedStep() async {
    final raw = await storage.read(checkpointKey);
    if (raw == null) {
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw _unreadableCheckpoint();
    }
    if (decoded is! Map) {
      throw _unreadableCheckpoint();
    }
    final from = decoded['from'];
    final to = decoded['to'];
    final snapshot = decoded['snapshot'];
    if (from is! int || to is! int || snapshot is! Map) {
      throw _unreadableCheckpoint();
    }
    final current = int.tryParse(await storage.read(versionKey) ?? '') ?? 0;
    if (current >= to) {
      // The step completed; only its checkpoint was left behind.
      await storage.delete(checkpointKey);
      return;
    }
    final before = <String, String>{};
    for (final entry in snapshot.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is String && value is String) {
        before[key] = value;
      }
    }
    await _restore(before);
    await storage.write(versionKey, '$from');
    await storage.delete(checkpointKey);
  }

  Failure _unreadableCheckpoint() {
    return Failure(
      code: FailureCode.storageWriteFailed,
      message: 'The storage migration checkpoint is unreadable.',
      kind: FailureKind.unknown,
      details: const <String, Object?>{'checkpoint': 'unreadable'},
    );
  }

  Future<void> _runStep(StorageMigration migration, int fromVersion) async {
    final nextVersion = fromVersion + 1;
    final before = await _snapshot();
    await _writeCheckpoint(fromVersion, nextVersion, before);
    try {
      await migration(storage);
      await storage.write(versionKey, '$nextVersion');
    } catch (error, stackTrace) {
      try {
        await _restore(before);
      } catch (rollbackError) {
        throw Failure(
          code: FailureCode.storageWriteFailed,
          message: 'Storage migration failed and could not be fully restored.',
          kind: FailureKind.unknown,
          details: <String, Object?>{
            'rollbackFailed': true,
            'originalError': '$error',
            'rollbackError': '$rollbackError',
          },
        );
      }
      await _deleteCheckpointSafely();
      Error.throwWithStackTrace(error, stackTrace);
    }
    await _deleteCheckpointSafely();
  }

  Future<Map<String, String>> _snapshot() async {
    final before = <String, String>{};
    for (final key in await storage.keys()) {
      if (key == checkpointKey) {
        continue;
      }
      final value = await storage.read(key);
      if (value != null) {
        before[key] = value;
      }
    }
    return before;
  }

  Future<void> _writeCheckpoint(
    int from,
    int to,
    Map<String, String> snapshot,
  ) {
    return storage.write(
      checkpointKey,
      jsonEncode(<String, Object?>{
        'from': from,
        'to': to,
        'snapshot': snapshot,
      }),
    );
  }

  /// A leftover checkpoint is harmless because recovery compares versions, so a
  /// failed delete must not fail the migration that already committed.
  Future<void> _deleteCheckpointSafely() async {
    try {
      await storage.delete(checkpointKey);
    } on Object {
      // Recovery discards it once the version proves the step completed.
    }
  }

  Future<void> _restore(Map<String, String> before) async {
    for (final key in await storage.keys()) {
      if (!before.containsKey(key)) {
        await storage.delete(key);
      }
    }
    for (final entry in before.entries) {
      await storage.write(entry.key, entry.value);
    }
  }
}
