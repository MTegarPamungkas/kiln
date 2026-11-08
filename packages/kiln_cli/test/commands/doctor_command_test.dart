import 'dart:convert';
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

    test('warns when a feature layer import points outward', () async {
      final useCase = File(
        p.join(
          project.path,
          'lib',
          'features',
          'notes',
          'domain',
          'usecases',
          'add_note.dart',
        ),
      );
      await useCase.create(recursive: true);
      await useCase.writeAsString(
        "import 'package:test_app/features/notes/data/models/note_dto.dart';\n"
        'void main() {}\n',
      );

      final runner = buildTestRunner(cwd: project, captured: captured);
      final code = await runner.run(<String>['doctor']);

      expect(code, ExitCodes.success);
      expect(captured.out.join('\n'), contains('domain/ must not import'));
    });

    test('accepts a feature that follows the layer rules', () async {
      final feature = p.join(project.path, 'lib', 'features', 'notes');
      final entity = File(p.join(feature, 'domain', 'entities', 'note.dart'));
      await entity.create(recursive: true);
      await entity.writeAsString('final class Note {}\n');
      final bloc = File(
        p.join(feature, 'presentation', 'bloc', 'notes_bloc.dart'),
      );
      await bloc.create(recursive: true);
      await bloc.writeAsString(
        "import 'package:test_app/features/notes/domain/entities/note.dart';\n"
        'void main() {}\n',
      );

      final runner = buildTestRunner(cwd: project, captured: captured);
      final code = await runner.run(<String>['doctor', '--json']);

      expect(code, ExitCodes.success);
      expect(captured.out.join('\n'), isNot(contains('"layer.')));
    });

    group('kiln_core source', () {
      /// Rewrites the fixture pubspec with [coreBlock] as the kiln_core entry.
      Future<void> writeCore(String coreBlock) async {
        await File(p.join(project.path, 'pubspec.yaml')).writeAsString('''
name: test_app
description: Test project.
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.13.0

dependencies:
$coreBlock
  dio: any
''');
      }

      /// The `core.source` doctor check from a `--json` run.
      Future<Map<String, Object?>> coreCheck(int expectedCode) async {
        final runner = buildTestRunner(cwd: project, captured: captured);
        final code = await runner.run(<String>['doctor', '--json']);
        expect(code, expectedCode, reason: captured.err.join('\n'));
        final report =
            jsonDecode(captured.out.join('\n').trim()) as Map<String, Object?>;
        final checks = report['checks'] as List<Object?>;
        return checks
            .cast<Map<String, Object?>>()
            .firstWhere((check) => check['id'] == 'core.source');
      }

      test('warns when kiln_core comes from a local path', () async {
        await writeCore('  kiln_core:\n    path: $corePath');

        final check = await coreCheck(ExitCodes.success);

        expect(check['status'], 'warn');
        expect(check['message'], contains('local path'));
      });

      test('warns when kiln_core is asked from pub.dev', () async {
        await writeCore('  kiln_core: ^0.1.0');

        final check = await coreCheck(ExitCodes.success);

        expect(check['status'], 'warn');
        expect(check['message'], contains('no release is published'));
      });

      test('warns when a git source tracks the default branch', () async {
        await writeCore('''
  kiln_core:
    git:
      url: https://github.com/kiln-dev/kiln.git
      path: packages/kiln_core''');

        final check = await coreCheck(ExitCodes.success);

        expect(check['status'], 'warn');
        expect(check['message'], contains('default branch'));
      });

      test('accepts a git source pinned to a ref', () async {
        await writeCore('''
  kiln_core:
    git:
      url: https://github.com/kiln-dev/kiln.git
      path: packages/kiln_core
      ref: v0.1.0''');

        final check = await coreCheck(ExitCodes.success);

        expect(check['status'], 'ok');
        expect(check['message'], contains('v0.1.0'));
      });

      test('fails when kiln_core is missing entirely', () async {
        await writeCore('  intl: ^0.20.3');

        final check = await coreCheck(ExitCodes.project);

        expect(check['status'], 'fail');
        expect(check['message'], contains('not a dependency'));
      });
    });
  });
}
