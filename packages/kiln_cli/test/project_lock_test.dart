import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

import 'support/cli_support.dart';

void main() {
  late Directory project;
  setUp(() async => project = await createTempProject());
  tearDown(() async => project.delete(recursive: true));

  for (final args in <List<String>>[
    ['add', 'dio', '--yes', '--no-verify'],
    ['remove', 'dio', '--yes'],
    ['setup', '--all'],
    ['upgrade'],
    ['repair'],
    ['rollback'],
    ['doctor', '--fix'],
  ]) {
    test(
      '${args.join(' ')} rejects an independently held lock before writing',
      () async {
        final captured = CapturedLogger();
        final runner = buildTestRunner(cwd: project, captured: captured);
        final lock = await ProjectLock.acquire(project);
        final config = File('${project.path}/kiln.yaml');
        final before = await config.readAsString();
        try {
          expect(await runner.run(args), isNot(0));
          expect(captured.err.join('\n'), contains('modifying this project'));
          expect(await config.readAsString(), before);
        } finally {
          lock.release();
        }
      },
    );
  }

  test('read-only doctor can inspect a locked project', () async {
    final captured = CapturedLogger();
    final runner = buildTestRunner(cwd: project, captured: captured);
    final lock = await ProjectLock.acquire(project);
    try {
      await runner.run(['doctor']);
      expect(
        captured.err.join('\n'),
        isNot(contains('modifying this project')),
      );
    } finally {
      lock.release();
    }
  });

  for (final args in <List<String>>[
    ['setup'],
    ['setup', '--all', '--dry-run'],
    [
      'add',
      'dio',
      '--dry-run',
      '--yes',
      '--no-verify',
      '--answer',
      'base_url=https://example.test',
    ],
  ]) {
    test(
      '${args.join(' ')} remains read-only while another operation owns the lock',
      () async {
        final captured = CapturedLogger();
        final runner = buildTestRunner(cwd: project, captured: captured);
        final lock = await ProjectLock.acquire(project);
        final config = File('${project.path}/kiln.yaml');
        final before = await config.readAsString();
        try {
          expect(await runner.run(args), 0, reason: captured.err.join('\n'));
          expect(await config.readAsString(), before);
        } finally {
          lock.release();
        }
      },
    );
  }
}
