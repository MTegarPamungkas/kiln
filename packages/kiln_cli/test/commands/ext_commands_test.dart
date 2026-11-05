import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

void main() {
  group('kiln ext', () {
    late Directory workspace;
    late CapturedLogger captured;

    setUp(() async {
      workspace = await Directory.systemTemp.createTemp('kiln_ext_');
      captured = CapturedLogger();
    });

    tearDown(() async {
      await workspace.delete(recursive: true);
    });

    test('new, validate, and pack an extension', () async {
      final runner = buildTestRunner(cwd: workspace, captured: captured);

      final newCode = await runner.run(<String>[
        'ext',
        'new',
        'hello',
        '--name',
        'Hello extension',
        '--category',
        'tooling',
        '--provides',
        'hello',
      ]);
      expect(newCode, ExitCodes.success, reason: captured.err.join('\n'));

      final extensionRoot = Directory(
        p.join(workspace.path, 'extensions', 'hello'),
      );
      expect(
        File(p.join(extensionRoot.path, 'extension.yaml')).existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(
            extensionRoot.path,
            'brick',
            '__brick__',
            'lib',
            'extensions',
            'hello',
            'hello_module.dart',
          ),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(extensionRoot.path, 'test', 'manifest_test.dart'))
            .existsSync(),
        isTrue,
      );

      captured.clear();
      final validateCode = await runner.run(<String>[
        'ext',
        'validate',
        p.join('extensions', 'hello'),
      ]);
      expect(validateCode, ExitCodes.success, reason: captured.err.join('\n'));

      captured.clear();
      final packCode = await runner.run(<String>[
        'ext',
        'pack',
        p.join('extensions', 'hello'),
      ]);
      expect(packCode, ExitCodes.success, reason: captured.err.join('\n'));
      expect(
        File(p.join(workspace.path, 'hello-0.1.0.tgz')).existsSync(),
        isTrue,
      );
    });

    test('validate rejects an invalid manifest', () async {
      final extension = Directory(p.join(workspace.path, 'broken'));
      await extension.create(recursive: true);
      await File(p.join(extension.path, 'extension.yaml')).writeAsString('''
id: Bad-Id
name: Broken
version: nope
description: Broken extension.
category: tooling
''');
      final runner = buildTestRunner(cwd: workspace, captured: captured);

      final code = await runner.run(<String>[
        'ext',
        'validate',
        'broken',
        '--json',
      ]);

      expect(code, ExitCodes.project);
      expect(captured.out.join('\n'), contains('"valid": false'));
    });
  });
}
