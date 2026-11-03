import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('Transaction', () {
    late Directory project;
    late File existing;
    late File deleted;

    setUp(() async {
      project = await Directory.systemTemp.createTemp('kiln_tx_');
      existing = File('${project.path}/lib/existing.dart');
      deleted = File('${project.path}/lib/deleted.dart');
      await existing.parent.create(recursive: true);
      await existing.writeAsString('old');
      await deleted.writeAsString('delete me');
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('writes, snapshots, commits, and rolls back from history', () {
      final transaction = Transaction.begin(project)
        ..writeText('lib/existing.dart', 'new')
        ..writeText('lib/created.dart', 'created')
        ..deleteFile('lib/deleted.dart');

      expect(existing.readAsStringSync(), 'new');
      expect(File('${project.path}/lib/created.dart').existsSync(), isTrue);
      expect(deleted.existsSync(), isFalse);

      transaction.commit();

      expect(Directory('${project.path}/.kiln/journal').listSync(), isEmpty);
      final history = const Rollback().latestCommitted(project);
      expect(history, isNotNull);

      const Rollback().run(history!);

      expect(existing.readAsStringSync(), 'old');
      expect(File('${project.path}/lib/created.dart').existsSync(), isFalse);
      expect(deleted.readAsStringSync(), 'delete me');
    });

    test('rollback restores an interrupted transaction', () {
      final transaction = Transaction.begin(project)
        ..writeText('lib/existing.dart', 'broken')
        ..writeText('lib/created.dart', 'created');

      final interrupted = Journal.latest(
        project,
        status: JournalStatus.running,
      );
      expect(interrupted, isNotNull);

      const Rollback().run(interrupted!);
      expect(existing.readAsStringSync(), 'old');
      expect(File('${project.path}/lib/created.dart').existsSync(), isFalse);

      // Keep the analyzer happy about the transaction variable.
      expect(transaction.journal.id, isNotEmpty);
    });

    test('commit can discard history', () {
      Transaction.begin(project)
        ..writeText('lib/existing.dart', 'final')
        ..commit(keepHistory: false);

      expect(const Rollback().latestCommitted(project), isNull);
      expect(Directory('${project.path}/.kiln/backups').existsSync(), isFalse);
    });
  });
}
