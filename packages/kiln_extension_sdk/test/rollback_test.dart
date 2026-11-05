import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('Rollback', () {
    test('reverses every operation in reverse order', () async {
      final project = await Directory.systemTemp.createTemp('kiln_rollback_');
      final first = File('${project.path}/a.txt');
      final second = File('${project.path}/b.txt');
      await first.writeAsString('a');
      await second.writeAsString('b');

      final transaction = Transaction.begin(project)
        ..writeText('a.txt', 'changed')
        ..deleteFile('b.txt')
        ..writeText('c.txt', 'created');

      transaction.rollback();

      expect(first.readAsStringSync(), 'a');
      expect(second.readAsStringSync(), 'b');
      expect(File('${project.path}/c.txt').existsSync(), isFalse);
      expect(
        File('${project.path}/.kiln/journal/${transaction.journal.id}.json')
            .existsSync(),
        isFalse,
      );
      expect(transaction.snapshots.directory.existsSync(), isFalse);
      await project.delete(recursive: true);
    });

    test('latestInterrupted finds a running journal', () async {
      final project = await Directory.systemTemp.createTemp('kiln_rollback_');
      final transaction = Transaction.begin(project)
        ..writeText('a.txt', 'content');

      final journal = const Rollback().latestInterrupted(project);
      expect(journal?.id, transaction.journal.id);

      const Rollback().run(journal!);
      expect(File('${project.path}/a.txt').existsSync(), isFalse);
      await project.delete(recursive: true);
    });
  });
}
