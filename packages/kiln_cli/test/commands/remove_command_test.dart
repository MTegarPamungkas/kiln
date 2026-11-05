import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

void main() {
  group('kiln remove', () {
    late Directory project;
    late CapturedLogger captured;

    setUp(() async {
      project = await createTempProject();
      captured = CapturedLogger();
      final runner = buildTestRunner(cwd: project, captured: captured);
      await runner.run(<String>[
        'add',
        'dio',
        '--answer',
        'base_url=https://api.example.com',
        '--no-verify',
        '--yes',
      ]);
      captured.clear();
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('removes owned files, patches, dependency, and lock entry', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['remove', 'dio', '--yes']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(
        File(
          p.join(project.path, 'lib', 'extensions', 'dio', 'dio_module.dart'),
        ).existsSync(),
        isFalse,
      );
      expect(
        File(
          p.join(
            project.path,
            'android',
            'app',
            'src',
            'main',
            'AndroidManifest.xml',
          ),
        ).readAsStringSync(),
        isNot(contains('android.permission.INTERNET')),
      );
      expect(
        File(p.join(project.path, 'kiln.lock.yaml')).readAsStringSync(),
        contains('extensions: {}'),
      );
      expect(
        File(p.join(project.path, 'pubspec.yaml')).readAsStringSync(),
        isNot(contains('dio:')),
      );
    });

    test('a dry run keeps everything', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'remove',
        'dio',
        '--dry-run',
        '--yes',
      ]);

      expect(code, ExitCodes.success);
      expect(
        File(
          p.join(project.path, 'lib', 'extensions', 'dio', 'dio_module.dart'),
        ).existsSync(),
        isTrue,
      );
    });

    test('removing an unknown extension fails', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['remove', 'missing', '--yes']);

      expect(code, ExitCodes.project);
      expect(captured.err.join('\n'), contains('not installed'));
    });
  });
}
