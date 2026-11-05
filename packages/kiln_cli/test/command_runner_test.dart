import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:test/test.dart';

import 'support/cli_support.dart';

void main() {
  group('KilnCommandRunner', () {
    late Directory project;
    late CapturedLogger captured;

    setUp(() async {
      project = await createTempProject();
      captured = CapturedLogger();
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('version prints the CLI and core versions', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['version']);

      expect(code, ExitCodes.success);
      expect(
        captured.out.join('\n'),
        matches(RegExp(r'kiln \d+\.\d+\.\d+')),
      );
      expect(
        captured.out.join('\n'),
        matches(RegExp(r'kiln_core \d+\.\d+\.\d+')),
      );
    });

    test('version --json is machine readable', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['version', '--json']);

      expect(code, ExitCodes.success);
      expect(
        captured.out.join('\n'),
        matches(RegExp(r'"kiln": "\d+\.\d+\.\d+"')),
      );
    });

    test('an unknown command returns the usage exit code', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['nope']);

      expect(code, ExitCodes.usage);
      expect(captured.err.join('\n'), contains('nope'));
    });

    test('list --available shows the bundled catalog', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['list', '--available']);

      expect(code, ExitCodes.success);
      expect(captured.out.join('\n'), matches(RegExp(r'dio \d+\.\d+\.\d+')));
    });

    test('list --json includes installed and available', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'list',
        '--installed',
        '--available',
        '--json',
      ]);

      expect(code, ExitCodes.success);
      final output = captured.out.join('\n');
      expect(output, contains('"installed"'));
      expect(output, contains('"available"'));
    });
  });
}
