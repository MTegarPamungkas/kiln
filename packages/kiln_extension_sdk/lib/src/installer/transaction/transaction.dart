import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'journal.dart';
import 'rollback.dart';
import 'snapshot.dart';

/// Applies file operations with a journal and pre-change snapshots.
final class Transaction {
  Transaction._({
    required this.projectRoot,
    required this.journal,
    required this.snapshots,
  });

  factory Transaction.begin(Directory projectRoot) {
    final journal = Journal.create(projectRoot);
    journal.save();
    return Transaction._(
      projectRoot: projectRoot,
      journal: journal,
      snapshots: SnapshotStore(projectRoot, journal.id),
    );
  }

  final Directory projectRoot;
  final Journal journal;
  final SnapshotStore snapshots;

  void writeText(String relativePath, String content) {
    writeFile(relativePath, utf8.encode(content));
  }

  void writeFile(String relativePath, List<int> bytes) {
    final target = File(p.join(projectRoot.path, relativePath));
    final existed = target.existsSync();
    if (existed) {
      snapshots.backup(relativePath);
    }
    journal.add(
      JournalOperation(
        type: JournalOperationType.write,
        path: relativePath,
        existed: existed,
      ),
    );
    target.parent.createSync(recursive: true);
    target.writeAsBytesSync(bytes);
  }

  void renameFile(String fromPath, String toPath) {
    final source = File(p.join(projectRoot.path, fromPath));
    if (!source.existsSync()) {
      return;
    }
    writeFile(toPath, source.readAsBytesSync());
    deleteFile(fromPath);
  }

  void deleteFile(String relativePath) {
    final target = File(p.join(projectRoot.path, relativePath));
    if (!target.existsSync()) {
      return;
    }
    snapshots.backup(relativePath);
    journal.add(
      JournalOperation(
        type: JournalOperationType.delete,
        path: relativePath,
        existed: true,
      ),
    );
    target.deleteSync();
  }

  /// Marks the transaction complete and keeps its backups for `kiln rollback`.
  void commit({bool keepHistory = true}) {
    journal.markCommitted();
    if (!keepHistory) {
      journal.deleteFile();
      snapshots.deleteAll();
      return;
    }
    snapshots.directory.createSync(recursive: true);
    final history = File(p.join(snapshots.directory.path, 'journal.json'));
    if (journal.file.existsSync()) {
      journal.file.renameSync(history.path);
    }
  }

  void rollback() {
    const Rollback().run(journal);
  }
}
