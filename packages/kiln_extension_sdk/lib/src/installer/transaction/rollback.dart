import 'dart:io';

import 'package:path/path.dart' as p;

import '../../kiln_exception.dart';
import 'journal.dart';
import 'root_path.dart';
import 'snapshot.dart';

/// Restores files from a journal and its snapshots.
final class Rollback {
  const Rollback();

  /// Reverses [journal] in place and removes the journal and its backups.
  void run(Journal journal) {
    final snapshots = SnapshotStore(journal.projectRoot, journal.id);
    // Validate the complete journal before restoring or deleting anything.
    RootPath.validateId(journal.id);
    journal.file;
    snapshots.directory;
    for (final operation in journal.operations) {
      RootPath(journal.projectRoot).resolve(operation.path);
      final snapshot = snapshots.backupFile(operation.path);
      if ((operation.existed ||
              operation.type == JournalOperationType.delete) &&
          !snapshot.existsSync()) {
        throw KilnException(
          'Transaction ${journal.id} cannot restore "${operation.path}": snapshot is missing.',
          code: 'rollback.snapshot_missing',
          suggestion: 'Recover the missing snapshot before retrying rollback.',
        );
      }
    }
    for (final operation in journal.operations.reversed) {
      final target = File(
        RootPath(journal.projectRoot).resolve(operation.path),
      );
      switch (operation.type) {
        case JournalOperationType.write:
          if (operation.existed) {
            snapshots.restore(operation.path);
          } else if (target.existsSync()) {
            target.deleteSync();
          }
        case JournalOperationType.delete:
          snapshots.restore(operation.path);
      }
    }
    journal.deleteFile();
    snapshots.deleteAll();
  }

  /// The newest completed transaction, if one can be rolled back.
  Journal? latestCommitted(Directory projectRoot) =>
      _committed(projectRoot).firstOrNull;

  /// Keeps only the newest completed rollback entries.
  void pruneHistory(Directory projectRoot, {required int keep}) {
    for (final journal in _committed(projectRoot).skip(keep)) {
      SnapshotStore(projectRoot, journal.id).deleteAll();
    }
  }

  Iterable<Journal> _committed(Directory projectRoot) sync* {
    final backups = Directory(RootPath(projectRoot).resolve('.kiln/backups'));
    if (!backups.existsSync()) {
      return;
    }
    final journals = <({File file, DateTime modified})>[];
    for (final entity in backups.listSync(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final file = File(p.join(entity.path, 'journal.json'));
      if (file.existsSync()) {
        journals.add((file: file, modified: file.lastModifiedSync()));
      }
    }
    journals.sort((left, right) => right.modified.compareTo(left.modified));
    for (final entry in journals) {
      try {
        final journal = Journal.fromFile(entry.file, projectRoot: projectRoot);
        if (journal.status == JournalStatus.committed &&
            journal.id == p.basename(entry.file.parent.path)) {
          yield journal;
        }
      } catch (_) {
        continue;
      }
    }
  }

  /// The newest transaction that has not finished publishing its history.
  Journal? latestInterrupted(Directory projectRoot) =>
      Journal.latest(projectRoot);
}
