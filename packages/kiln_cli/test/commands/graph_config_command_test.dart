import 'dart:convert';
import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

void main() {
  group('kiln graph', () {
    late Directory project;
    late CapturedLogger captured;

    setUp(() async {
      project = await createTempProject();
      captured = CapturedLogger();
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

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

    test('says so when no extension is installed', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['graph']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(captured.out.join('\n'), contains('No extensions installed yet.'));
    });

    test('lists installed extensions as text', () async {
      await addDio();
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['graph']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(captured.out.join('\n'), contains('dio'));
    });

    test('--format mermaid emits a flowchart', () async {
      await addDio();
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['graph', '--format', 'mermaid']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(captured.out.join('\n'), contains('flowchart TD'));
    });

    test('--json wraps the rendered graph', () async {
      await addDio();
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'graph',
        '--format',
        'mermaid',
        '--json',
      ]);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      final report =
          jsonDecode(captured.out.join('\n').trim()) as Map<String, Object?>;
      expect(report['format'], 'mermaid');
      expect(report['graph'], contains('flowchart TD'));
    });

    test('rejects an unknown format', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['graph', '--format', 'dot']);

      expect(code, ExitCodes.usage);
    });
  });

  group('kiln config', () {
    late Directory project;
    late CapturedLogger captured;

    setUp(() async {
      project = await createTempProject();
      captured = CapturedLogger();
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    File globalConfigFile() =>
        File(p.join(testHomeFor(project), '.kiln', 'config.yaml'));

    test('prints the bundled defaults', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['config']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      final out = captured.out.join('\n');
      expect(out, contains('registry: (bundled)'));
      expect(out, contains('mirror: (none)'));
      expect(out, contains('offline: false'));
    });

    test('writes the registry url into kiln.yaml', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'config',
        '--registry',
        'https://example.com/index.json',
      ]);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(
        File(p.join(project.path, 'kiln.yaml')).readAsStringSync(),
        contains('https://example.com/index.json'),
      );
      expect(
        globalConfigFile().existsSync(),
        isFalse,
        reason: 'a project write must not touch the global config',
      );
    });

    test('--global writes to the injected home and not the real one', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'config',
        '--global',
        '--offline',
        '--registry',
        'https://mirror.example.com/index.json',
      ]);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      final saved = globalConfigFile().readAsStringSync();
      expect(saved, contains('https://mirror.example.com/index.json'));
      expect(saved, contains('offline: true'));
      expect(globalConfigFile().path, startsWith(project.path));
    });

    test('--json reports the settings', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'config',
        '--registry',
        'https://example.com/index.json',
        '--json',
      ]);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      final report =
          jsonDecode(captured.out.join('\n').trim()) as Map<String, Object?>;
      expect(report['registry'], 'https://example.com/index.json');
      expect(report['offline'], isFalse);
    });
  });
}
