import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

void main() {
  group('kiln upgrade bundled catalog', () {
    late Directory project;
    late CapturedLogger captured;
    late File module;
    late File lockfile;

    setUp(() async {
      project = await createTempProject();
      captured = CapturedLogger();
      final runner = buildTestRunner(cwd: project, captured: captured);
      final add = await runner.run(<String>[
        'add',
        'connectivity',
        '--answer',
        'base_url=https://api.example.com',
        '--no-verify',
        '--yes',
      ]);
      expect(add, ExitCodes.success, reason: captured.err.join('\n'));

      module = File(
        p.join(
          project.path,
          'lib',
          'extensions',
          'connectivity',
          'connectivity_module.dart',
        ),
      );
      lockfile = File(p.join(project.path, 'kiln.lock.yaml'));
      final source = lockfile.readAsStringSync();
      final old = source.replaceFirst(
        '  connectivity:\n    version: "0.1.2"',
        '  connectivity:\n    version: "0.1.1"',
      );
      expect(old, isNot(source), reason: 'the fixture must look like 0.1.1');
      lockfile.writeAsStringSync(old);
      // A user edit forces the upgrade to pass --force, proving the generated
      // file is replaced rather than left behind.
      module.writeAsStringSync('// legacy connectivity\n');
      captured.clear();
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('upgrades from the bundled catalog without a registry', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'upgrade',
        '--all',
        '--yes',
        '--no-verify',
        '--force',
      ]);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(captured.out.join('\n'), contains('connectivity 0.1.1 -> 0.1.2'));
      expect(captured.out.join('\n'), isNot(contains('Configure a registry')));
      expect(module.readAsStringSync(), isNot(contains('legacy connectivity')));
      expect(module.readAsStringSync(), contains('ConnectivityModule'));
      expect(lockfile.readAsStringSync(), contains('version: "0.1.2"'));
      expect(lockfile.readAsStringSync(), isNot(contains('version: "0.1.1"')));
    });

    test('a dry run lists the bundled upgrade without writing', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'upgrade',
        '--all',
        '--dry-run',
        '--yes',
      ]);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(captured.out.join('\n'), contains('connectivity 0.1.1 -> 0.1.2'));
      expect(module.readAsStringSync(), '// legacy connectivity\n');
      expect(lockfile.readAsStringSync(), contains('version: "0.1.1"'));
    });
  });
}
