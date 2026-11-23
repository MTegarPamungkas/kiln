import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../kiln_exception.dart';
import 'journal.dart';
import 'rollback.dart';
import 'root_path.dart';
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

  /// Capture a file before a verifier or another external managed-file writer.
  void capture(String relativePath) {
    final target = File(RootPath(projectRoot).resolve(relativePath));
    final existed = target.existsSync();
    if (existed) snapshots.backup(relativePath);
    journal.add(
      JournalOperation(
        type: JournalOperationType.write,
        path: relativePath,
        existed: existed,
      ),
    );
  }

  void writeText(String relativePath, String content) {
    writeFile(relativePath, utf8.encode(content));
  }

  void writeFile(String relativePath, List<int> bytes) {
    final target = File(RootPath(projectRoot).resolve(relativePath));
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
    final source = File(RootPath(projectRoot).resolve(fromPath));
    RootPath(projectRoot).resolve(toPath);
    if (!source.existsSync()) {
      return;
    }
    writeFile(toPath, source.readAsBytesSync());
    deleteFile(fromPath);
  }

  void deleteFile(String relativePath) {
    final target = File(RootPath(projectRoot).resolve(relativePath));
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

  /// Marks the transaction complete and retains the latest ten rollback entries.
  ///
  /// Once the journal records [JournalStatus.committed] the project state is
  /// final: publishing history is bookkeeping, so a failure there must not
  /// reach a caller that would then roll the verified install back. A journal
  /// left in `.kiln/journal` still reads as committed, so
  /// [Rollback.latestInterrupted] can recover it later.
  void commit({bool keepHistory = true}) {
    journal.markCommitted();
    if (!keepHistory) {
      _bestEffort(() {
        journal.deleteFile();
        snapshots.deleteAll();
      });
      return;
    }
    _bestEffort(() {
      snapshots.directory.createSync(recursive: true);
      final history = File(p.join(snapshots.directory.path, 'journal.json'));
      if (journal.file.existsSync()) {
        _renameWithRetry(journal.file, history.path);
      }
      const Rollback().pruneHistory(projectRoot, keep: 10);
    });
  }

  /// Runs post-commit bookkeeping without letting it fail the transaction.
  ///
  /// `RootPath` and the snapshot store reject unsafe ids and links with
  /// [KilnException], and the filesystem can fail with [FileSystemException].
  /// Both are retention problems, not install problems.
  void _bestEffort(void Function() action) {
    try {
      action();
    } on FileSystemException {
      // Retention is best effort after the transaction is already committed.
    } on KilnException {
      // An unusable history entry must not undo a committed transaction.
    }
  }

  /// Renames the journal, retrying the sharing violations Windows scanners and
  /// indexers produce. [Journal.save] already retries its own replacement.
  void _renameWithRetry(File source, String destination) {
    for (var attempt = 0; ; attempt++) {
      try {
        source.renameSync(destination);
        return;
      } on FileSystemException catch (error) {
        final code = error.osError?.errorCode;
        if (!Platform.isWindows ||
            (code != 5 && code != 32 && code != 33) ||
            attempt == 7) {
          rethrow;
        }
        sleep(Duration(milliseconds: 25 * (attempt + 1)));
      }
    }
  }

  void rollback() {
    const Rollback().run(journal);
  }
}
