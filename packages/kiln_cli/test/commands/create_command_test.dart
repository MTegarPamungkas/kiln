import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../support/cli_support.dart';

Future<ProcessResult> _fakeFlutter(
  String executable,
  List<String> arguments,
  String? workingDirectory,
) async {
  if (arguments.isNotEmpty && arguments.first == 'create') {
    final target = Directory(arguments.last);
    await target.create(recursive: true);
    await File(p.join(target.path, 'pubspec.yaml')).writeAsString('''
name: created_app
publish_to: none
version: 1.0.0
environment:
  sdk: ^3.13.0
dependencies:
  flutter:
    sdk: flutter
''');
    for (final platform in <String>['android', 'ios', 'web']) {
      await Directory(p.join(target.path, platform)).create(recursive: true);
    }
    final manifest = File(
      p.join(
        target.path,
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      ),
    );
    await manifest.parent.create(recursive: true);
    await manifest.writeAsString('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="created_app">
        <activity android:name=".MainActivity"/>
    </application>
</manifest>
''');
    await File(p.join(target.path, 'test', 'widget_test.dart'))
        .create(recursive: true);
  }
  return ProcessResult(0, 0, 'ok', '');
}

void main() {
  group('kiln create', () {
    late Directory workspace;
    late CapturedLogger captured;

    setUp(() async {
      workspace = await Directory.systemTemp.createTemp('kiln_create_');
      captured = CapturedLogger();
    });

    tearDown(() async {
      await workspace.delete(recursive: true);
    });

    test(
      'renders the minimal template and installs selected extensions',
      () async {
        final runner = buildTestRunner(
          cwd: workspace,
          captured: captured,
          processRunner: FakeProcessRunner(_fakeFlutter),
        );

        final code = await runner.run(<String>[
          'create',
          'created_app',
          '--org',
          'com.kiln.demo',
          '--core-path',
          corePath,
          '--with',
          'dio',
          '--answer',
          'base_url=https://api.example.com',
          '--yes',
        ]);

        final target = Directory(p.join(workspace.path, 'created_app'));
        expect(code, ExitCodes.success, reason: captured.err.join('\n'));
        expect(
          File(p.join(target.path, 'lib', 'main.dart')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(target.path, 'lib', 'app', 'app.dart')).existsSync(),
          isTrue,
        );
        final main = File(p.join(target.path, 'lib', 'main.dart'))
            .readAsStringSync();
        expect(main, contains('HomePage'));
        expect(
          File(p.join(target.path, 'lib', 'features', 'home', 'home_page.dart'))
              .existsSync(),
          isTrue,
        );
        expect(
          File(p.join(target.path, 'lib', 'app', 'app_shell.dart'))
              .readAsStringSync(),
          isNot(contains('StarterPage')),
        );
        expect(
          File(p.join(target.path, 'test', 'widget_test.dart')).existsSync(),
          isFalse,
        );
        expect(
          File(
            p.join(target.path, 'lib', 'extensions', 'dio', 'dio_module.dart'),
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            p.join(
              target.path,
              'lib',
              'extensions',
              'l10n',
              'l10n_module.dart',
            ),
          ).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(target.path, 'lib', 'core', 'l10n', 'app_strings.dart'))
              .existsSync(),
          isFalse,
        );

        final pubspec = loadYaml(
          File(p.join(target.path, 'pubspec.yaml')).readAsStringSync(),
        ) as YamlMap;
        expect(pubspec['dependency_overrides'], isNotNull);

        final config = loadYaml(
          File(p.join(target.path, 'kiln.yaml')).readAsStringSync(),
        ) as YamlMap;
        expect((config['project'] as YamlMap)['name'], 'created_app');
        expect(config['state'], 'none');
      },
    );

    test('renders the starter template when requested', () async {
      final runner = buildTestRunner(
        cwd: workspace,
        captured: captured,
        processRunner: FakeProcessRunner(_fakeFlutter),
      );

      final code = await runner.run(<String>[
        'create',
        'starter_app',
        '--template',
        'app',
        '--core-path',
        corePath,
        '--yes',
      ]);

      final target = Directory(p.join(workspace.path, 'starter_app'));
      expect(code, ExitCodes.success, reason: captured.err.join('\n'));
      expect(
        File(p.join(target.path, 'lib', 'main.dart')).readAsStringSync(),
        isNot(contains('HomePage')),
      );
      expect(
        File(p.join(target.path, 'lib', 'app', 'app_shell.dart'))
            .readAsStringSync(),
        contains('StarterHome'),
      );
    });

    test('repair restores generated files and preserves edited ARBs', () async {
      final createRunner = buildTestRunner(
        cwd: workspace,
        captured: captured,
        processRunner: FakeProcessRunner(_fakeFlutter),
      );
      final createCode = await createRunner.run(<String>[
        'create',
        'created_app',
        '--core-path',
        corePath,
        '--yes',
      ]);
      expect(createCode, ExitCodes.success, reason: captured.err.join('\n'));

      final target = Directory(p.join(workspace.path, 'created_app'));
      final generated = File(
        p.join(target.path, 'test', 'extensions', 'l10n', 'l10n_test.dart'),
      );
      final original = generated.readAsStringSync();
      generated.writeAsStringSync('$original\n// user formatting edit\n');

      final arb = File(p.join(target.path, 'lib', 'l10n', 'app_id.arb'));
      final arbSource = arb.readAsStringSync();
      arb.writeAsStringSync('$arbSource\n');

      final codegen = File(
        p.join(target.path, 'lib', 'extensions', 'extensions.g.dart'),
      );
      final codegenSource = codegen.readAsStringSync();
      codegen.writeAsStringSync('// broken codegen\n');

      final repairRunner = buildTestRunner(
        cwd: target,
        captured: captured,
        processRunner: FakeProcessRunner(_fakeFlutter),
      );
      final repairCode = await repairRunner.run(<String>[
        'repair',
        'l10n',
        '--yes',
      ]);

      expect(repairCode, ExitCodes.success, reason: captured.err.join('\n'));
      expect(generated.readAsStringSync(), original);
      expect(arb.readAsStringSync(), '$arbSource\n');
      expect(codegen.readAsStringSync(), codegenSource);
    });

    test('rejects an invalid application name', () async {
      final runner = buildTestRunner(
        cwd: workspace,
        captured: captured,
        processRunner: FakeProcessRunner(_fakeFlutter),
      );

      final code = await runner.run(<String>['create', 'Bad-Name']);

      expect(code, ExitCodes.usage);
      expect(captured.err.join('\n'), contains('snake_case'));
    });
  });
}
