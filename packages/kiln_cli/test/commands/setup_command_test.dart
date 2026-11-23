import 'dart:convert';
import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

Map<String, String> _files(Directory root) => {
  for (final file in root.listSync(recursive: true).whereType<File>())
    if (!p
        .relative(file.path, from: root.path)
        .startsWith('.kiln${p.separator}'))
      p.relative(file.path, from: root.path): base64Encode(
        file.readAsBytesSync(),
      ),
};

/// Each test starts by installing the full Appwrite bundle into a temp project,
/// which is why `packages/kiln_cli/dart_test.yaml` allows two minutes per test.
void main() {
  late Directory project;
  late CapturedLogger captured;

  setUp(() async {
    project = await createTempProject();
    captured = CapturedLogger();
    final runner = buildTestRunner(cwd: project, captured: captured);
    expect(
      await runner.run(['add', 'appwrite', '--no-verify', '--yes']),
      ExitCodes.success,
    );
    captured.clear();
  });

  tearDown(() async => project.delete(recursive: true));

  test(
    'setup persists a build-variable reference and renders no literal value',
    () async {
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(
        await runner.run(['add', 'analytics', '--yes', '--no-verify']),
        ExitCodes.success,
      );
      expect(
        await runner.run([
          'setup',
          'analytics',
          '--yes',
          '--no-verify',
          '--answer',
          'api_key=env:CLIENT_ANALYTICS_KEY',
        ]),
        ExitCodes.success,
      );
      final saved = ProjectContext.load(project).extensionAnswers['analytics']!;
      expect(saved['api_key'], 'env:CLIENT_ANALYTICS_KEY');
      final source = File(
        p.join(
          project.path,
          'lib',
          'extensions',
          'analytics',
          'analytics_config.dart',
        ),
      ).readAsStringSync();
      expect(
        source,
        contains("const String.fromEnvironment('CLIENT_ANALYTICS_KEY')"),
      );
      expect(source, isNot(contains('env:CLIENT_ANALYTICS_KEY')));
      expect(
        await runner.run(['setup', 'analytics', '--yes', '--dry-run']),
        ExitCodes.success,
      );
    },
  );

  test('doctor identifies demo settings and gives a setup command', () async {
    final runner = buildTestRunner(cwd: project, captured: captured);
    expect(await runner.run(['doctor', '--json']), ExitCodes.project);
    final report = jsonDecode(captured.out.join('\n')) as Map<String, dynamic>;
    final checks = (report['checks'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final setup = checks.firstWhere((check) => check['id'] == 'setup.appwrite');
    expect(setup['status'], 'fail');
    expect(setup['suggestion'], 'Run kiln setup appwrite');
    expect(
      checks.any((check) => check['id'] == 'setup.appwrite.project_id'),
      isTrue,
    );
  });

  test('requires installation and rejects unsupported services', () async {
    final empty = await createTempProject();
    addTearDown(() => empty.delete(recursive: true));
    final runner = buildTestRunner(cwd: empty, captured: captured);
    final before = _files(empty);
    expect(await runner.run(['setup', 'appwrite', '--yes']), ExitCodes.project);
    expect(captured.out.join(), contains('Run kiln add appwrite'));
    expect(await runner.run(['setup', 'unknown']), ExitCodes.project);
    expect(_files(empty), before);
  });

  test('cancelled input leaves project files unchanged', () async {
    final before = _files(project);
    final runner = buildTestRunner(
      cwd: project,
      captured: captured,
      prompter: Prompter(
        interactive: true,
        readLine: (_) => null,
        write: (_) {},
      ),
    );
    expect(await runner.run(['setup', 'appwrite']), ExitCodes.cancelled);
    expect(_files(project), before);
  });

  test(
    'doctor reports invalid saved settings without exposing their values',
    () async {
      ProjectContext.load(project).updateExtensionAnswers('appwrite', {
        'endpoint': 'https://user:private_value@example.com/v1',
        'project_id': 42,
        'database_id': '',
        'bucket_id': 'bucket with spaces',
      });
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(
        await runner.run(['doctor', '--fix', '--json']),
        ExitCodes.project,
      );
      final output = captured.out.join();
      for (final name in [
        'endpoint',
        'project_id',
        'database_id',
        'bucket_id',
      ]) {
        expect(output, contains('setup.appwrite.$name'));
      }
      expect(output, isNot(contains('private_value')));
      expect(
        ProjectContext.load(project)
            .extensionAnswers['appwrite']?['project_id'],
        42,
      );
    },
  );

  test('saves settings, renders source, and keeps ownership in sync', () async {
    final runner = buildTestRunner(cwd: project, captured: captured);
    expect(
      await runner.run([
        'setup',
        'appwrite',
        '--answer',
        'project_id=my_project',
        '--answer',
        'endpoint=https://api.example.com/v1',
        '--no-verify',
        '--yes',
      ]),
      ExitCodes.success,
      reason: captured.err.join('\n'),
    );
    final source = File(
      p.join(project.path, 'lib/extensions/appwrite/appwrite_config.dart'),
    ).readAsStringSync();
    expect(source, contains("projectId: 'my_project'"));
    expect(source, contains("endpoint: 'https://api.example.com/v1'"));
    expect(
      ProjectContext.load(project).extensionAnswers['appwrite']?['project_id'],
      'my_project',
    );
    captured.clear();
    expect(await runner.run(['doctor', '--json']), ExitCodes.success);
    final output = captured.out.join('\n');
    expect(output, contains('Appwrite is locally configured'));
    expect(output, isNot(contains('was edited by the user')));
  });

  test(
    'dry run previews configuration without changing project files',
    () async {
      final before = _files(project);
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(
        await runner.run([
          'setup',
          'appwrite',
          '--answer',
          'project_id=preview_project',
          '--dry-run',
          '--json',
        ]),
        ExitCodes.success,
      );
      expect(_files(project), before);
      final report =
          jsonDecode(captured.out.join('\n')) as Map<String, dynamic>;
      expect(report['status'], 'preview');
      expect(report['connection_checked'], isFalse);
      expect(report['verification'], 'not_run');
    },
  );

  test(
    'interactive setup preserves defaults and reasks invalid input',
    () async {
      final input = ['', 'invalid project', 'real_project', '', ''].iterator;
      final prompts = <String>[];
      final runner = buildTestRunner(
        cwd: project,
        captured: captured,
        prompter: Prompter(
          interactive: true,
          readLine: (_) {
            expect(input.moveNext(), isTrue);
            return input.current;
          },
          write: prompts.add,
        ),
      );
      expect(
        await runner.run(['setup', 'appwrite', '--no-verify']),
        ExitCodes.success,
      );
      expect(prompts.join(), contains('must contain only'));
      final saved = ProjectContext.load(project).extensionAnswers['appwrite']!;
      expect(saved['project_id'], 'real_project');
      expect(saved['endpoint'], 'https://cloud.appwrite.io/v1');
      expect(saved['database_id'], 'kiln');
    },
  );

  test('explicit answers override previously saved values', () async {
    final runner = buildTestRunner(cwd: project, captured: captured);
    for (final id in ['first_project', 'second_project']) {
      expect(
        await runner.run([
          'setup',
          'appwrite',
          '--answer',
          'appwrite.project_id=$id',
          '--no-verify',
          '--yes',
        ]),
        ExitCodes.success,
        reason: captured.err.join('\n'),
      );
      expect(
        ProjectContext.load(project)
            .extensionAnswers['appwrite']?['project_id'],
        id,
      );
    }
  });

  for (final answer in [
    null,
    'project_id=kiln_demo',
    "project_id=bad'id",
    'project_id=bad\$id',
    'endpoint=https://user:password@example.com/v1',
    'endpoint=https://api.example.com/v1?key=sensitive',
    'api_key=sensitive',
  ]) {
    test(
      'rejects invalid or unsupported settings without writing: $answer',
      () async {
        final before = _files(project);
        final runner = buildTestRunner(cwd: project, captured: captured);
        expect(
          await runner.run([
            'setup',
            'appwrite',
            '--yes',
            '--no-verify',
            if (answer != null) ...['--answer', answer],
          ]),
          ExitCodes.project,
        );
        expect(_files(project), before);
        expect(captured.out.join(), isNot(contains('sensitive')));
        expect(captured.err.join(), isNot(contains('sensitive')));
      },
    );
  }

  test('refuses to replace edited extension files', () async {
    final file = File(
      p.join(project.path, 'lib/extensions/appwrite/appwrite_config.dart'),
    );
    file.writeAsStringSync(
      '${file.readAsStringSync()}\n// User customization\n',
    );
    final before = _files(project);
    final runner = buildTestRunner(cwd: project, captured: captured);
    expect(
      await runner.run([
        'setup',
        'appwrite',
        '--answer',
        'project_id=real_project',
        '--no-verify',
        '--yes',
      ]),
      ExitCodes.conflict,
    );
    expect(_files(project), before);
  });

  test(
    'verification failure restores configuration, source, and pub lock',
    () async {
      final pubLock = File(p.join(project.path, 'pubspec.lock'))
        ..writeAsStringSync('original lock');
      final before = _files(project);
      final calls = <List<String>>[];
      final runner = buildTestRunner(
        cwd: project,
        captured: captured,
        processRunner: FakeProcessRunner((
          executable,
          arguments,
          workingDirectory,
        ) async {
          calls.add(arguments);
          pubLock.writeAsStringSync('changed by pub');
          return ProcessResult(0, arguments.first == 'analyze' ? 1 : 0, '', '');
        }),
      );
      expect(
        await runner.run([
          'setup',
          'appwrite',
          '--answer',
          'project_id=real_project',
          '--yes',
          '--json',
        ]),
        ExitCodes.verification,
      );
      expect(calls, [
        ['pub', 'get'],
        ['analyze'],
      ]);
      expect(_files(project), before);
      final report =
          jsonDecode(captured.out.join('\n')) as Map<String, dynamic>;
      expect(report['status'], 'failed');
      expect(report['verification'], 'failed');
    },
  );

  test('setup leaves dependent push extensions installed', () async {
    final runner = buildTestRunner(cwd: project, captured: captured);
    expect(
      await runner.run(['add', 'appwrite_push_native', '--no-verify', '--yes']),
      ExitCodes.success,
    );
    final push = File(
      p.join(
        project.path,
        'lib/extensions/appwrite_push_native/appwrite_push_native_module.dart',
      ),
    );
    final before = push.readAsStringSync();
    expect(
      await runner.run([
        'setup',
        'appwrite',
        '--answer',
        'project_id=real_project',
        '--yes',
        '--no-verify',
      ]),
      ExitCodes.success,
      reason: captured.err.join('\n'),
    );
    expect(push.readAsStringSync(), before);
    expect(
      ProjectContext.load(project).lockfile.ids,
      contains('appwrite_push_native'),
    );
  });

  test('rollback restores settings and generated source together', () async {
    final before = _files(project);
    final runner = buildTestRunner(cwd: project, captured: captured);
    expect(
      await runner.run([
        'setup',
        'appwrite',
        '--answer',
        'project_id=real_project',
        '--no-verify',
        '--yes',
      ]),
      ExitCodes.success,
    );
    expect(await runner.run(['rollback']), ExitCodes.success);
    expect(_files(project), before);
  });

  test(
    'rejects catalog version mismatch without rewriting the extension',
    () async {
      final lock = File(p.join(project.path, 'kiln.lock.yaml'));
      final current = ProjectContext.load(project)
          .lockfile
          .extensions['appwrite']!
          .version;
      lock.writeAsStringSync(
        lock.readAsStringSync().replaceFirst(
          'version: "$current"',
          'version: "9.9.9"',
        ),
      );
      final before = _files(project);
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(
        await runner.run([
          'setup',
          'appwrite',
          '--answer',
          'project_id=real_project',
          '--no-verify',
          '--yes',
        ]),
        ExitCodes.project,
      );
      expect(_files(project), before);
      expect(captured.err.join(), contains('does not match'));
    },
  );
}
