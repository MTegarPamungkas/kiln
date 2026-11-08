import 'dart:convert';
import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

void main() {
  group('kiln rollback', () {
    late Directory project;
    late CapturedLogger captured;

    setUp(() async {
      project = await createTempProject();
      captured = CapturedLogger();
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    File projectFile(String relative) => File(p.join(project.path, relative));

    /// Installs `dio`, which leaves one committed transaction and its backups.
    Future<void> addDio() async {
      final runner = buildTestRunner(cwd: project, captured: captured);
      final code = await runner.run(<String>[
        'add',
        'dio',
        '--answer',
        'base_url=https://api.example.com',
        '--no-verify',
        '--yes',
      ]);
      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      captured.clear();
    }

    test('reports nothing to roll back in a fresh project', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['rollback']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(captured.out.join('\n'), contains('No operation to roll back.'));
    });

    test('--list reports no interrupted or completed transaction', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['rollback', '--list']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      final out = captured.out.join('\n');
      expect(out, contains('Interrupted: none'));
      expect(out, contains('Completed: none'));
    });

    test('reverses the last committed transaction', () async {
      await addDio();
      final moduleFile = projectFile(
        p.join('lib', 'extensions', 'dio', 'dio_module.dart'),
      );
      expect(moduleFile.existsSync(), isTrue);

      final runner = buildTestRunner(cwd: project, captured: captured);
      final code = await runner.run(<String>['rollback']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(captured.out.join('\n'), contains('Last operation rolled back.'));
      expect(moduleFile.existsSync(), isFalse);
      expect(projectFile('pubspec.yaml').readAsStringSync(), isNot(contains('dio:')));
      // `add` created the lockfile, so reverting it removes the file again.
      expect(projectFile('kiln.lock.yaml').existsSync(), isFalse);
      expect(
        projectFile(
          p.join(
            'android',
            'app',
            'src',
            'main',
            'AndroidManifest.xml',
          ),
        ).readAsStringSync(),
        isNot(contains('android.permission.INTERNET')),
      );
      expect(_backupDirectories(project), isEmpty);
    });

    test('--list --json reports the committed transaction id', () async {
      await addDio();

      final runner = buildTestRunner(cwd: project, captured: captured);
      final code = await runner.run(<String>['rollback', '--list', '--json']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      final decoded = jsonDecode(captured.out.join('\n').trim());
      expect(decoded, isA<Map<String, Object?>>());
      final report = decoded as Map<String, Object?>;
      expect(report['interrupted'], isNull);
      expect(report['committed'], isA<String>());
      expect(report['committed'], isNotEmpty);
    });

    test('an interrupted transaction wins over the last committed one', () async {
      await addDio();
      final appFile = projectFile(p.join('lib', 'main.dart'));
      final original = appFile.readAsStringSync();
      final moduleFile = projectFile(
        p.join('lib', 'extensions', 'dio', 'dio_module.dart'),
      );

      const id = '1700000000000000';
      final snapshot = projectFile(
        p.join('.kiln', 'backups', id, 'lib', 'main.dart'),
      )..parent.createSync(recursive: true);
      snapshot.writeAsStringSync(original);
      final journal = projectFile(p.join('.kiln', 'journal', '$id.json'))
        ..parent.createSync(recursive: true);
      journal.writeAsStringSync(
        jsonEncode(<String, Object?>{
          'id': id,
          'started_at': DateTime.now().toUtc().toIso8601String(),
          'status': 'running',
          'operations': <Object?>[
            <String, Object?>{
              'type': 'write',
              'path': 'lib/main.dart',
              'existed': true,
            },
          ],
        }),
      );
      appFile.writeAsStringSync('// half-installed\n');

      final runner = buildTestRunner(cwd: project, captured: captured);
      final code = await runner.run(<String>['rollback']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(
        captured.out.join('\n'),
        contains('Interrupted operation rolled back.'),
      );
      expect(appFile.readAsStringSync(), original);
      expect(journal.existsSync(), isFalse);
      expect(
        moduleFile.existsSync(),
        isTrue,
        reason: 'the committed dio transaction must stay applied',
      );
    });
  });
}

/// The backup folders left under `.kiln/backups`, ignoring a missing folder.
List<String> _backupDirectories(Directory project) {
  final backups = Directory(p.join(project.path, '.kiln', 'backups'));
  if (!backups.existsSync()) {
    return const <String>[];
  }
  return backups
      .listSync()
      .whereType<Directory>()
      .map((directory) => p.basename(directory.path))
      .toList(growable: false);
}
