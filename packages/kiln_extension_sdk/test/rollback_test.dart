import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

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

    test(
      'a writer killed mid-transaction is recovered by the next process',
      () async {
        final project = await Directory.systemTemp.createTemp('kiln_rollback_');
        final userFile = File('${project.path}/user.txt');
        await userFile.writeAsString('user edit');
        final ownedFile = File('${project.path}/owned.txt');
        await ownedFile.writeAsString('original');

        final config = await Isolate.packageConfig;
        final helper = File('${project.path}/writer.dart');
        await helper.writeAsString('''
import 'dart:io';
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
Future<void> main(List<String> args) async {
  final project = Directory(args.single);
  Transaction.begin(project)
    ..writeText('owned.txt', 'half written')
    ..writeText('new.txt', 'created by writer');
  stdout.writeln('written');
  await stdout.flush();
  await stdin.first;
}
''');
        final child = await Process.start(Platform.resolvedExecutable, [
          '--packages=${config!.toFilePath()}',
          helper.path,
          project.path,
        ]);
        try {
          final ready = await child.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .first
              .timeout(const Duration(seconds: 20));
          expect(ready, 'written');
          // The half-applied state is on disk while the writer is blocked.
          expect(ownedFile.readAsStringSync(), 'half written');
          child.kill();
          await child.exitCode.timeout(const Duration(seconds: 10));
        } finally {
          child.kill();
          await child.exitCode;
        }

        // A fresh process finds the interrupted journal and reverses it.
        final interrupted = const Rollback().latestInterrupted(project);
        expect(interrupted, isNotNull);
        const Rollback().run(interrupted!);

        expect(ownedFile.readAsStringSync(), 'original');
        expect(File('${project.path}/new.txt').existsSync(), isFalse);
        // An unrelated user file is never part of the journal, so it survives.
        expect(userFile.readAsStringSync(), 'user edit');
        expect(const Rollback().latestInterrupted(project), isNull);

        await project.delete(recursive: true);
      },
    );
  });
}
