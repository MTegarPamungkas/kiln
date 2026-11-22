import 'dart:convert';
import 'dart:io';

import 'package:kiln_cli/kiln_cli.dart';
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

Map<String, String> snapshot(Directory root) => {
  for (final file in root.listSync(recursive: true).whereType<File>())
    if (!p
        .relative(file.path, from: root.path)
        .startsWith('.kiln${p.separator}'))
      p.relative(file.path, from: root.path): base64Encode(
        file.readAsBytesSync(),
      ),
};

List<String> get installAnswers => [
  '--answer',
  'base_url=https://api.example.com',
  '--answer',
  'url=https://example.supabase.co',
  '--answer',
  'anon_key=client_publishable_test',
  '--answer',
  'project_id=test_project',
];

String alternative(AvailableExtension extension, PromptSpec prompt) {
  if (prompt.isMulti) return prompt.options.first;
  return switch (prompt.type) {
    PromptType.boolValue => '${prompt.defaultValue != true}',
    PromptType.intValue =>
      '${(prompt.defaultValue as int? ?? prompt.min ?? 1) + 1}',
    PromptType.enumValue => prompt.options.firstWhere(
      (value) => value != prompt.defaultValue,
    ),
    PromptType.url => 'https://configured.example.com/v1',
    _ when prompt.name == 'seed_color' => '#123456',
    _ when prompt.name == 'scheme' => 'kiln-test',
    _ when prompt.name == 'dsn' => 'https://public@example.com/1',
    _ when prompt.name.contains('endpoint') =>
      'https://config.example.com/flags',
    _ => 'configured_test',
  };
}

void main() {
  for (final extension in extensionCatalog) {
    test('configures ${extension.id} from its manifest', () async {
      final project = await createTempProject();
      addTearDown(() => project.delete(recursive: true));
      final options = File(p.join(project.path, 'lib/firebase_options.dart'));
      options.writeAsStringSync('// Local configuration fixture.\n');
      final captured = CapturedLogger();
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(
        await runner.run([
          'add',
          if (const {
            'appwrite_push_native',
            'social_login',
          }.contains(extension.id))
            'appwrite',
          extension.id,
          ...installAnswers,
          '--no-verify',
          '--yes',
        ]),
        ExitCodes.success,
        reason: captured.err.join('\n'),
      );
      captured.clear();
      final before = snapshot(project);
      final prompts = extension.manifest.prompts;
      final prompt = prompts.isEmpty ? null : prompts.first;
      final args = [
        'setup',
        extension.id,
        '--yes',
        '--no-verify',
        '--json',
        if (prompt != null) ...[
          '--answer',
          '${prompt.name}=${alternative(extension, prompt)}',
        ],
      ];
      expect(
        await runner.run([...args, '--dry-run']),
        ExitCodes.success,
        reason: captured.err.join('\n'),
      );
      expect(
        snapshot(project),
        before,
        reason: 'preview must not write project files',
      );
      captured.clear();
      expect(
        await runner.run(args),
        ExitCodes.success,
        reason: captured.err.join('\n'),
      );
      final report =
          jsonDecode(captured.out.join('\n')) as Map<String, dynamic>;
      expect(report['status'], 'configured');
      expect(report['connection_checked'], isFalse);
      expect(report['next_steps'], isNotEmpty);
      if (prompt == null) {
        expect(
          snapshot(project),
          before,
          reason: 'extensions without prompts need no regeneration',
        );
      } else {
        expect(report['changed_extensions'], contains(extension.id));
        expect(snapshot(project), isNot(before));
      }
      captured.clear();
      expect(
        await runner.run(['doctor', '--json']),
        ExitCodes.success,
        reason: captured.out.join('\n'),
      );
      expect(
        captured.out.join('\n'),
        isNot(contains('was edited by the user')),
      );
    }, timeout: const Timeout(Duration(minutes: 2)));
  }

  group('configuration batches', () {
    late Directory project;
    late CapturedLogger captured;

    setUp(() async {
      project = await createTempProject();
      captured = CapturedLogger();
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(
        await runner.run([
          'add',
          'dio',
          'http_retry',
          'notifications',
          ...installAnswers,
          '--no-verify',
          '--yes',
        ]),
        ExitCodes.success,
      );
      captured.clear();
    });
    tearDown(() => project.delete(recursive: true));

    const changes = [
      '--answer',
      'dio.connect_timeout=42',
      '--answer',
      'http_retry.max_attempts=7',
      '--answer',
      'notifications.exact_alarms=true',
    ];

    test('lists settings without values and without changing files', () async {
      final before = snapshot(project);
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(await runner.run(['setup', '--json']), ExitCodes.success);
      expect(snapshot(project), before);
      final output = captured.out.join('\n');
      expect(output, contains('connect_timeout'));
      expect(output, isNot(contains('https://api.example.com')));
    });

    test(
      'applies all settings and native patches in one rollbackable transaction',
      () async {
        final before = snapshot(project);
        final runner = buildTestRunner(cwd: project, captured: captured);
        expect(
          await runner.run([
            'setup',
            '--all',
            ...changes,
            '--no-verify',
            '--yes',
            '--json',
          ]),
          ExitCodes.success,
          reason: captured.err.join('\n'),
        );
        final context = ProjectContext.load(project);
        expect(context.extensionAnswers['dio']?['connect_timeout'], 42);
        expect(context.extensionAnswers['http_retry']?['max_attempts'], 7);
        final manifest = File(
          p.join(project.path, 'android/app/src/main/AndroidManifest.xml'),
        ).readAsStringSync();
        expect(manifest, contains('SCHEDULE_EXACT_ALARM'));
        expect(await runner.run(['rollback']), ExitCodes.success);
        expect(snapshot(project), before);
      },
    );

    test('a failed verification restores the entire batch', () async {
      final before = snapshot(project);
      final calls = <List<String>>[];
      final runner = buildTestRunner(
        cwd: project,
        captured: captured,
        processRunner: FakeProcessRunner((
          executable,
          args,
          workingDirectory,
        ) async {
          calls.add(args);
          return ProcessResult(0, args.first == 'analyze' ? 1 : 0, '', '');
        }),
      );
      expect(
        await runner.run(['setup', '--all', ...changes, '--yes', '--json']),
        ExitCodes.verification,
      );
      expect(snapshot(project), before);
      expect(calls, [
        ['pub', 'get'],
        ['analyze'],
      ], reason: 'verify once for the whole batch');
    });

    test('a conflict in a later extension prevents every change', () async {
      final file = File(
        p.join(
          project.path,
          'lib/extensions/notifications/notifications_module.dart',
        ),
      );
      file.writeAsStringSync('${file.readAsStringSync()}\n// User edit\n');
      final before = snapshot(project);
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(
        await runner.run([
          'setup',
          '--all',
          ...changes,
          '--yes',
          '--no-verify',
        ]),
        ExitCodes.conflict,
      );
      expect(snapshot(project), before);
    });

    test('repeated unchanged settings preserve customized source', () async {
      final file = File(
        p.join(project.path, 'lib/extensions/dio/dio_config.dart'),
      );
      file.writeAsStringSync('${file.readAsStringSync()}\n// User edit\n');
      final before = snapshot(project);
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(
        await runner.run(['setup', 'dio', '--yes', '--json']),
        ExitCodes.success,
      );
      expect(snapshot(project), before);
      final report =
          jsonDecode(captured.out.join('\n')) as Map<String, dynamic>;
      expect(report['changed_extensions'], isEmpty);
    });

    test('rejects incompatible selection flags before writing', () async {
      final before = snapshot(project);
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(await runner.run(['setup', 'dio', '--all']), ExitCodes.usage);
      expect(snapshot(project), before);
    });
  });
}
