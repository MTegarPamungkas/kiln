import 'dart:io';

import 'package:path/path.dart' as p;

/// Stores pre-change copies under `.kiln/backups/<transaction id>/`.
final class SnapshotStore {
  SnapshotStore(this.projectRoot, this.transactionId);

  final Directory projectRoot;
  final String transactionId;

  Directory get directory =>
      Directory(p.join(projectRoot.path, '.kiln', 'backups', transactionId));

  File backupFile(String relativePath) =>
      File(p.join(directory.path, relativePath));

  bool hasBackup(String relativePath) => backupFile(relativePath).existsSync();

  void backup(String relativePath) {
    if (hasBackup(relativePath)) {
      return;
    }
    final source = File(p.join(projectRoot.path, relativePath));
    if (!source.existsSync()) {
      return;
    }
    final target = backupFile(relativePath);
    target.parent.createSync(recursive: true);
    source.copySync(target.path);
  }

  void restore(String relativePath) {
    final backup = backupFile(relativePath);
    if (!backup.existsSync()) {
      return;
    }
    final target = File(p.join(projectRoot.path, relativePath));
    target.parent.createSync(recursive: true);
    target.writeAsBytesSync(backup.readAsBytesSync());
  }

  void deleteAll() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
    final parent = directory.parent;
    if (parent.existsSync() && parent.listSync().isEmpty) {
      parent.deleteSync();
    }
  }
}
