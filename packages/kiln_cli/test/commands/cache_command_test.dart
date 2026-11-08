import 'dart:convert';
import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

void main() {
  group('kiln cache', () {
    late Directory project;
    late CapturedLogger captured;

    setUp(() async {
      project = await createTempProject();
      captured = CapturedLogger();
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    Directory cacheDirectory() =>
        Directory(p.join(testHomeFor(project), '.kiln', 'cache'));

    test('reports an empty cache', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>['cache']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      final out = captured.out.join('\n');
      expect(out, contains('Cache: ${cacheDirectory().path}'));
      expect(out, contains('(empty)'));
    });

    test('counts entries and clean removes them', () async {
      final registry = Directory(p.join(cacheDirectory().path, 'registry'))
        ..createSync(recursive: true);
      File(p.join(registry.path, 'index.json')).writeAsStringSync('{}');

      final runner = buildTestRunner(cwd: project, captured: captured);
      await runner.run(<String>['cache']);
      expect(captured.out.join('\n'), contains('1 entries'));

      captured.clear();
      final code = await runner.run(<String>['cache', 'clean']);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(captured.out.join('\n'), contains('Cache cleaned:'));
      expect(cacheDirectory().existsSync(), isFalse);
    });

    test('--json reports the path and the cleaned flag', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'cache',
        'clean',
        '--json',
      ]);

      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      final report =
          jsonDecode(captured.out.join('\n').trim()) as Map<String, Object?>;
      expect(report['path'], cacheDirectory().path);
      expect(report['cleaned'], isTrue);
      expect(report['entries'], 0);
    });
  });
}
