import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('SnapshotStore', () {
    late Directory project;
    late File file;

    setUp(() async {
      project = await Directory.systemTemp.createTemp('kiln_snapshot_');
      file = File('${project.path}/lib/file.txt');
      await file.parent.create(recursive: true);
      await file.writeAsString('before');
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('backs up once and restores the original content', () {
      final snapshots = SnapshotStore(project, 'tx-1');
      snapshots.backup('lib/file.txt');
      expect(snapshots.hasBackup('lib/file.txt'), isTrue);

      file.writeAsString('after');
      snapshots.restore('lib/file.txt');
      expect(file.readAsStringSync(), 'before');
    });

    test('does not overwrite the first backup', () async {
      final snapshots = SnapshotStore(project, 'tx-1');
      snapshots.backup('lib/file.txt');

      await file.writeAsString('second');
      snapshots.backup('lib/file.txt');
      snapshots.restore('lib/file.txt');

      expect(file.readAsStringSync(), 'before');
    });

    test('deleteAll removes the transaction backups', () {
      final snapshots = SnapshotStore(project, 'tx-1');
      snapshots.backup('lib/file.txt');
      snapshots.deleteAll();

      expect(snapshots.directory.existsSync(), isFalse);
    });
  });
}
