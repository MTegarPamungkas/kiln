import 'dart:convert';
import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../support/cli_support.dart';

void main() {
  group('kiln add', () {
    late Directory project;
    late CapturedLogger captured;

    setUp(() async {
      project = await createTempProject();
      captured = CapturedLogger();
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('installs dio and records every artifact', () async {
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
      expect(
        File(
          p.join(project.path, 'lib', 'extensions', 'dio', 'dio_module.dart'),
        ).existsSync(),
        isTrue,
      );
      expect(File(p.join(project.path, 'kiln.lock.yaml')).existsSync(), isTrue);
      expect(
        File(p.join(project.path, 'lib', 'extensions', 'extensions.g.dart'))
            .readAsStringSync(),
        contains('DioModule'),
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
        contains('android.permission.INTERNET'),
      );

      final pubspec = loadYaml(
        File(p.join(project.path, 'pubspec.yaml')).readAsStringSync(),
      ) as YamlMap;
      expect((pubspec['dependencies'] as YamlMap)['dio'], '^5.11.1');

      final config = loadYaml(
        File(p.join(project.path, 'kiln.yaml')).readAsStringSync(),
      ) as YamlMap;
      final extensions = config['extensions'] as YamlMap;
      expect(
        (extensions['dio'] as YamlMap)['base_url'],
        'https://api.example.com',
      );
    });

    test('a dry run writes nothing', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'add',
        'dio',
        '--answer',
        'base_url=https://api.example.com',
        '--dry-run',
        '--yes',
      ]);

      expect(code, ExitCodes.success);
      expect(
        File(p.join(project.path, 'kiln.lock.yaml')).existsSync(),
        isFalse,
      );
      expect(
        File(
          p.join(project.path, 'lib', 'extensions', 'dio', 'dio_module.dart'),
        ).existsSync(),
        isFalse,
      );
      expect(captured.out.join('\n'), contains('create'));
    });

    test('a missing required answer fails without writing', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'add',
        'dio',
        '--no-verify',
        '--yes',
      ]);

      expect(code, ExitCodes.project);
      expect(captured.err.join('\n'), contains('base_url'));
      expect(
        File(p.join(project.path, 'kiln.lock.yaml')).existsSync(),
        isFalse,
      );
    });

    test('a failed verification rolls back every managed change', () async {
      final runner = buildTestRunner(
        cwd: project,
        captured: captured,
        processRunner: FakeProcessRunner(
          (executable, arguments, workingDirectory) async =>
              ProcessResult(0, 1, 'analysis failed', ''),
        ),
      );

      final code = await runner.run(<String>[
        'add',
        'dio',
        '--answer',
        'base_url=https://api.example.com',
        '--yes',
      ]);

      expect(code, ExitCodes.verification);
      expect(captured.err.join('\n'), contains('rolled back'));
      expect(
        File(
          p.join(project.path, 'lib', 'extensions', 'dio', 'dio_module.dart'),
        ).existsSync(),
        isFalse,
      );
      expect(File(p.join(project.path, 'kiln.lock.yaml')).existsSync(), isFalse);
      expect(
        File(p.join(project.path, 'pubspec.yaml')).readAsStringSync(),
        isNot(contains('dio:')),
      );
      final config =
          loadYaml(File(p.join(project.path, 'kiln.yaml')).readAsStringSync())
              as YamlMap;
      expect((config['extensions'] as YamlMap).containsKey('dio'), isFalse);
    });

    test('--json reports a rolled-back verification failure', () async {
      final runner = buildTestRunner(
        cwd: project,
        captured: captured,
        processRunner: FakeProcessRunner(
          (executable, arguments, workingDirectory) async =>
              ProcessResult(0, 1, 'analysis failed', ''),
        ),
      );

      final code = await runner.run(<String>[
        'add',
        'dio',
        '--answer',
        'base_url=https://api.example.com',
        '--json',
        '--yes',
      ]);

      expect(code, ExitCodes.verification);
      final report =
          jsonDecode(captured.out.join('\n').trim()) as Map<String, Object?>;
      expect(report['status'], 'verification_failed');
      expect(report['committed'], isFalse);
    });

    test('adding an installed extension is a no-op', () async {
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

      final code = await runner.run(<String>[
        'add',
        'dio',
        '--answer',
        'base_url=https://api.example.com',
        '--no-verify',
        '--yes',
      ]);

      expect(code, ExitCodes.success);
      expect(captured.out.join('\n'), contains('No new extensions'));
    });
  });
}
