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
  });
}
