import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

void main() {
  group('kiln doctor', () {
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

    test('reports a healthy project', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['doctor', '--json']);

      expect(code, ExitCodes.success);
      expect(captured.out.join('\n'), contains('"ok": true'));
    });

    test('detects an out-of-sync codegen file and fixes it', () async {
      final codegen = File(
        p.join(project.path, 'lib', 'extensions', 'extensions.g.dart'),
      );
      await codegen.writeAsString('// broken');

      final runner = buildTestRunner(cwd: project, captured: captured);
      final before = await runner.run(<String>['doctor', '--json']);
      expect(before, ExitCodes.project);
      captured.clear();

      final fixed = await runner.run(<String>['doctor', '--fix', '--json']);

      expect(fixed, ExitCodes.success);
      expect(codegen.readAsStringSync(), contains('DioModule'));
    });
  });
}
