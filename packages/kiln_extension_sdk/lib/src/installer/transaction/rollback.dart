import 'dart:io';

import 'package:path/path.dart' as p;

import 'journal.dart';
import 'snapshot.dart';

/// Restores files from a journal and its snapshots.
final class Rollback {
  const Rollback();

  /// Reverses [journal] in place and removes the journal and its backups.
  void run(Journal journal) {
    final snapshots = SnapshotStore(journal.projectRoot, journal.id);
    for (final operation in journal.operations.reversed) {
      final target = File(p.join(journal.projectRoot.path, operation.path));
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
  Journal? latestCommitted(Directory projectRoot) {
    final backups = Directory(p.join(projectRoot.path, '.kiln', 'backups'));
    if (!backups.existsSync()) {
      return null;
    }
    final journals = <({File file, DateTime modified})>[];
    for (final entity in backups.listSync()) {
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
        return Journal.fromFile(entry.file, projectRoot: projectRoot);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// The newest transaction that was interrupted while running.
  Journal? latestInterrupted(Directory projectRoot) =>
      Journal.latest(projectRoot, status: JournalStatus.running);
}
