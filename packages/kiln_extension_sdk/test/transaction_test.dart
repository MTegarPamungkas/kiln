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

    test('missing snapshot prevents all restoration and keeps the journal', () {
      final transaction = Transaction.begin(project)
        ..writeText('lib/existing.dart', 'new')
        ..deleteFile('lib/deleted.dart');
      transaction.snapshots.backupFile('lib/existing.dart').deleteSync();
      expect(
        transaction.rollback,
        throwsA(
          isA<KilnException>().having(
            (error) => error.code,
            'code',
            'rollback.snapshot_missing',
          ),
        ),
      );
      expect(existing.readAsStringSync(), 'new');
      expect(deleted.existsSync(), isFalse);
      expect(transaction.journal.file.existsSync(), isTrue);
    });

    test('recovers a committed journal before the history rename', () {
      Transaction.begin(project)
        ..writeText('lib/existing.dart', 'old history')
        ..commit();
      final interrupted = Transaction.begin(project)
        ..writeText('lib/existing.dart', 'new');
      interrupted.journal.markCommitted();
      const rollback = Rollback();
      final pending = rollback.latestInterrupted(project);
      expect(pending?.id, interrupted.journal.id);
      expect(
        rollback.latestCommitted(project)?.id,
        isNot(interrupted.journal.id),
      );
      rollback.run(pending!);
      expect(existing.readAsStringSync(), 'old history');
      expect(rollback.latestInterrupted(project), isNull);
    });

    test('retains ten commits and leaves unfinished snapshots alone', () {
      final pending = Transaction.begin(project)
        ..writeText('lib/existing.dart', 'pending');
      for (var count = 0; count < 12; count++) {
        Transaction.begin(project)
          ..writeText('lib/deleted.dart', '$count')
          ..commit();
      }
      final entries = Directory('${project.path}/.kiln/backups').listSync();
      expect(entries, hasLength(11));
      expect(pending.snapshots.directory.existsSync(), isTrue);
      expect(const Rollback().latestCommitted(project), isNotNull);
    });

    test(
      'future lockfile versions reject mutations without rewriting metadata',
      () {
        final file = File('${project.path}/kiln.lock.yaml')
          ..writeAsStringSync(
            'lock_version: 3\ncore: 0.1.1\nextensions: {}\nfuture: true\n',
          );
        final before = file.readAsStringSync();
        expect(LockfileStore(project).read, throwsA(isA<KilnException>()));
        expect(file.readAsStringSync(), before);
      },
    );

    test('commit can discard history', () {
      Transaction.begin(project)
        ..writeText('lib/existing.dart', 'final')
        ..commit(keepHistory: false);

      expect(const Rollback().latestCommitted(project), isNull);
      expect(Directory('${project.path}/.kiln/backups').existsSync(), isFalse);
    });

    test('a failing history prune keeps the commit and the written files', () {
      // Fill history past the retention limit, then add one older entry whose
      // directory name is an id RootPath rejects. Pruning it throws
      // KilnException from validateId, not FileSystemException.
      for (var count = 0; count < 11; count++) {
        Transaction.begin(project)
          ..writeText('lib/deleted.dart', 'history $count')
          ..commit();
      }
      final backups = Directory('${project.path}/.kiln/backups');
      final unsafe = Directory('${backups.path}/unsafe id')
        ..createSync(recursive: true);
      final unsafeJournal = File('${unsafe.path}/journal.json')
        ..writeAsStringSync(
          '{"id": "unsafe id", "status": "committed", "operations": []}',
        );
      unsafeJournal.setLastModifiedSync(DateTime.utc(2000));

      final transaction = Transaction.begin(project)
        ..writeText('lib/existing.dart', 'committed');

      // The committed state is final; retention must not throw at the caller.
      expect(transaction.commit, returnsNormally);
      expect(existing.readAsStringSync(), 'committed');
      expect(unsafe.existsSync(), isTrue, reason: 'prune is best effort');
      expect(
        const Rollback().latestCommitted(project),
        isNotNull,
        reason: 'history must still be readable after a failed prune',
      );
    });

    test('transaction ids are unique within one microsecond', () {
      final ids = <String>{
        for (var index = 0; index < 50; index++)
          Journal.create(project).id,
      };
      expect(ids, hasLength(50));
      for (final id in ids) {
        expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id), isTrue);
      }
    });

    test('transaction ids avoid an existing journal and snapshot', () {
      final first = Journal.create(project);
      first.save();
      Directory('${project.path}/.kiln/backups/${first.id}')
          .createSync(recursive: true);

      final second = Journal.create(project);
      expect(second.id, isNot(first.id));
      expect(second.file.existsSync(), isFalse);
    });
  });
}
