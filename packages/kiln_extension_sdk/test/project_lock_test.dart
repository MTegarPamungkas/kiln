import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';

void main() {
  late Directory project;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('kiln_project_lock_');
  });
  tearDown(() async => project.delete(recursive: true));

  Matcher getBusy() => isA<KilnException>().having(
    (error) => error.code,
    'code',
    'project.busy',
  );

  test('unrelated same-process acquisitions cannot overlap', () async {
    final lock = await ProjectLock.acquire(project);
    try {
      await expectLater(ProjectLock.acquire(project), throwsA(getBusy()));
    } finally {
      lock.release();
      lock.release();
    }
    final next = await ProjectLock.acquire(project);
    next.release();
  });

  test('only the owning async context can reenter', () async {
    final lock = await ProjectLock.acquire(project);
    await lock.run(() async {
      final nested = await ProjectLock.acquire(project);
      nested.release();
      // Releasing a nested handle must not unlock the outer operation.
      expect(File('${project.path}/.kiln/project.lock').existsSync(), isTrue);
      final nextNested = await ProjectLock.acquire(project);
      await nextNested.run(() async {});
    });
    final next = await ProjectLock.acquire(project);
    next.release();
  });

  test(
    'another process cannot steal an old active lock; crash releases it',
    () async {
      final config = await Isolate.packageConfig;
      final helper = File('${project.path}/holder.dart');
      await helper.writeAsString('''
import 'dart:io';
import 'package:kiln_extension_sdk/src/installer/transaction/project_lock.dart';
Future<void> main(List<String> args) async {
  final lock = await ProjectLock.acquire(Directory(args.single));
  stdout.writeln('locked');
  await stdout.flush();
  await stdin.first;
  lock.release();
}
''');
      final child = await Process.start(Platform.resolvedExecutable, [
        '--packages=${config!.toFilePath()}',
        helper.path,
        project.path,
      ]);
      final errors = child.stderr.transform(utf8.decoder).join();
      try {
        final ready = await child.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .first
            .timeout(const Duration(seconds: 15));
        expect(ready, 'locked');
        await expectLater(
          ProjectLock.acquire(project, staleAfter: Duration.zero),
          throwsA(getBusy()),
        );
        child.kill();
        await child.exitCode.timeout(const Duration(seconds: 10));
        expect(await errors, isEmpty);
        final recovered = await ProjectLock.acquire(project);
        recovered.release();
      } finally {
        child.kill();
        await child.exitCode;
      }
    },
  );
}
