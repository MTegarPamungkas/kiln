import 'package:kiln_core/kiln_core.dart';

/// Exports and restores collections as JSON-compatible maps.
///
/// Import validates the complete document before touching the database and
/// compensates attempted writes if a write fails. Compensation failures are
/// reported explicitly.
///
/// Every import also writes a journal: the previous value of each record is
/// stored before the record is overwritten, and a status record marks the import
/// active until it commits. A process death in the middle of an import leaves
/// that journal behind, and [recover] (called at startup by the module, and at
/// the start of the next import) restores the previous values. Without a lock
/// the journal keeps the database consistent after a crash, but it cannot stop
/// two writers from importing at the same time; pass a [MutationLock] for that.
final class BackupExport {
  const BackupExport({
    this.journalCollection = '_kiln_import_journal',
    this.statusKey = '__status__',
  });

  /// Version written by [export] and accepted by [import].
  static const int currentVersion = 1;

  /// Collection holding the import journal (status plus one record per write).
  final String journalCollection;

  /// Key of the journal status record.
  final String statusKey;

  Future<Map<String, Object?>> export({
    required LocalDatabase database,
    required Iterable<String> collections,
  }) async {
    final data = <String, Object?>{};
    for (final collection in collections) {
      data[collection] = <Map<String, Object?>>[
        for (final record in await database.query(collection))
          <String, Object?>{'key': record.key, 'data': record.data},
      ];
    }
    return <String, Object?>{'version': currentVersion, 'collections': data};
  }

  /// Rolls back an interrupted import, returning true when it changed data.
  ///
  /// Safe to call at startup and when no import ever crashed: it then only
  /// clears leftover journal records.
  Future<bool> recover({required LocalDatabase database, MutationLock? lock}) {
    Future<bool> apply() => _recover(database);
    final guard = lock;
    return guard == null ? apply() : guard.runExclusive(apply);
  }

  Future<void> import({
    required LocalDatabase database,
    required Map<String, Object?> backup,
    MutationLock? lock,
  }) {
    Future<void> apply() => _import(database: database, backup: backup);
    final guard = lock;
    return guard == null ? apply() : guard.runExclusive(apply);
  }

  Future<bool> _recover(LocalDatabase database) async {
    final status = await database.get(journalCollection, statusKey);
    if (status == null) {
      await _clearJournal(database);
      return false;
    }
    if (status['active'] != true) {
      await _clearJournal(database);
      return false;
    }
    final entries = await database.query(journalCollection);
    final parsed =
        <({String collection, String key, Map<String, Object?>? previous})>[];
    for (final entry in entries) {
      if (entry.key == statusKey) {
        continue;
      }
      final collection = entry.data['collection'];
      final key = entry.data['key'];
      final previous = entry.data['previous'];
      if (collection is! String || key is! String) {
        throw const Failure(
          code: FailureCode.storageWriteFailed,
          message: 'The backup import journal is unreadable.',
          kind: FailureKind.unknown,
        );
      }
      parsed.add((
        collection: collection,
        key: key,
        previous: previous is Map ? Map<String, Object?>.from(previous) : null,
      ));
    }
    for (final item in parsed.reversed) {
      final previous = item.previous;
      if (previous == null) {
        await database.delete(item.collection, item.key);
      } else {
        await database.put(item.collection, item.key, previous);
      }
    }
    await _clearJournal(database);
    return parsed.isNotEmpty;
  }

  Future<void> _import({
    required LocalDatabase database,
    required Map<String, Object?> backup,
  }) async {
    final version = backup['version'];
    if (version is! int) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The backup has no version.',
        kind: FailureKind.validation,
      );
    }
    if (version != currentVersion) {
      throw Failure(
        code: FailureCode.validationUnsupportedValue,
        message: 'Backup version $version is not supported.',
        kind: FailureKind.validation,
        details: <String, Object?>{'version': version},
      );
    }
    final collections = backup['collections'];
    if (collections is! Map) {
      throw const Failure(
        code: FailureCode.validationInvalidInput,
        message: 'The backup has no collections map.',
        kind: FailureKind.validation,
      );
    }

    final records =
        <({String collection, String key, Map<String, Object?> data})>[];
    final identities = <(String, String)>{};
    for (final entry in collections.entries) {
      final collection = entry.key;
      if (collection is! String || collection.isEmpty) {
        throw const Failure(
          code: FailureCode.validationInvalidInput,
          message: 'Backup collection names must be non-empty strings.',
          kind: FailureKind.validation,
        );
      }
      final values = entry.value;
      if (values is! Iterable) {
        throw Failure(
          code: FailureCode.validationInvalidInput,
          message: 'Backup collection "$collection" is not a list.',
          kind: FailureKind.validation,
        );
      }
      for (final record in values) {
        if (record is! Map) {
          throw Failure(
            code: FailureCode.validationInvalidInput,
            message: 'Backup collection "$collection" has a malformed record.',
            kind: FailureKind.validation,
          );
        }
        final key = record['key'];
        final data = record['data'];
        if (key is! String || key.isEmpty || data is! Map) {
          throw Failure(
            code: FailureCode.validationInvalidInput,
            message:
                'Backup collection "$collection" has a record without a key '
                'or data.',
            kind: FailureKind.validation,
          );
        }
        final copied = _copyJson(data) as Map<String, Object?>;
        records.add((collection: collection, key: key, data: copied));
        if (!identities.add((collection, key))) {
          throw const Failure(
            code: FailureCode.validationInvalidInput,
            message: 'The backup contains duplicate record keys.',
            kind: FailureKind.validation,
          );
        }
        if (collection == journalCollection) {
          throw const Failure(
            code: FailureCode.validationInvalidInput,
            message: 'A backup may not write into the import journal.',
            kind: FailureKind.validation,
          );
        }
      }
    }

    // A previous process may have died inside an import.
    await _recover(database);

    final applied =
        <({String collection, String key, Map<String, Object?>? previous})>[];
    var index = 0;
    await database.put(journalCollection, statusKey, <String, Object?>{
      'active': true,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    try {
      for (final record in records) {
        final previous = await database.get(record.collection, record.key);
        // The journal record must be durable before the write it compensates.
        await database.put(
          journalCollection,
          '${index++}'.padLeft(8, '0'),
          <String, Object?>{
            'collection': record.collection,
            'key': record.key,
            'previous': previous,
          },
        );
        applied.add((
          collection: record.collection,
          key: record.key,
          previous: previous,
        ));
        // A backend can mutate successfully and then report a write failure.
        await database.put(record.collection, record.key, record.data);
      }
      // Mark the import committed before dropping the journal, so a crash here
      // cannot roll back a completed import.
      await database.put(journalCollection, statusKey, <String, Object?>{
        'active': false,
        'at': DateTime.now().toUtc().toIso8601String(),
      });
      await _clearJournal(database);
    } catch (error, stackTrace) {
      var rollbackFailed = false;
      for (final item in applied.reversed) {
        try {
          final previous = item.previous;
          if (previous == null) {
            await database.delete(item.collection, item.key);
          } else {
            await database.put(item.collection, item.key, previous);
          }
        } on Object {
          rollbackFailed = true;
        }
      }
      if (!rollbackFailed) {
        // The data is back to its previous state; drop the journal. If this
        // fails, the journal still rolls back to the same state on recovery.
        await _clearJournal(database);
      }
      if (rollbackFailed) {
        throw Failure(
          code: FailureCode.storageWriteFailed,
          message: 'Backup import failed and could not be fully restored.',
          kind: FailureKind.unknown,
          details: <String, Object?>{
            'rollbackFailed': true,
            'originalError': '$error',
          },
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _clearJournal(LocalDatabase database) async {
    try {
      for (final record in await database.query(journalCollection)) {
        await database.delete(journalCollection, record.key);
      }
    } on Object {
      // A leftover journal is idempotent: recovery restores the same values.
    }
  }

  static Object? _copyJson(Object? value, [int depth = 0]) {
    if (depth <= 64) {
      if (value == null ||
          value is String ||
          value is bool ||
          (value is num && value.isFinite)) {
        return value;
      }
      if (value is List) {
        return [for (final item in value) _copyJson(item, depth + 1)];
      }
      if (value is Map && value.keys.every((key) => key is String)) {
        return <String, Object?>{
          for (final entry in value.entries)
            entry.key as String: _copyJson(entry.value, depth + 1),
        };
      }
    }
    throw const Failure(
      code: FailureCode.validationInvalidInput,
      message:
          'Backup data must contain finite JSON values with string keys '
          'and at most 64 levels of nesting.',
      kind: FailureKind.validation,
    );
  }
}
