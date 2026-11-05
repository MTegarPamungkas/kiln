import 'dart:convert';
import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart' show MasonBundle;
import 'package:test/test.dart';

import 'support/fixtures.dart';

AvailableExtension _demoExtension({MasonBundle? bundle}) {
  return makeExtension(
    id: 'demo',
    name: 'Demo',
    provides: const ['demo'],
    dependencies: const {'demo_pkg': '^1.0.0'},
    platformSetup: const PlatformSetup(
      android: AndroidSetup(permissions: ['android.permission.INTERNET']),
      macos: MacosSetup(
        entitlements: {'com.apple.security.network.client': true},
      ),
    ),
    bundle: bundle ?? bundleFromFixture('tiny_brick'),
  );
}

void main() {
  group('ExtensionInstaller.add', () {
    late Directory project;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test(
      'installs files, dependencies, native patches, codegen, and lockfile',
      () async {
        final installer = ExtensionInstaller(
          projectRoot: project,
          available: [_demoExtension()],
          verifier: Verifier(
            runner: (executable, arguments, workingDirectory) async =>
                ProcessResult(0, 0, 'ok', ''),
          ),
        );

        final result = await installer.add(
          requested: const ['demo'],
          project: const {'name': 'fresh_app', 'org': 'com.example'},
          options: const InstallOptions(
            verify: false,
            collisionPolicy: CollisionPolicy.ask,
          ),
        );

        expect(result.hasConflicts, isFalse);
        expect(result.plan.added.single.id, 'demo');
        expect(result.success, isTrue);
        expect(result.patches, contains('android.permission.INTERNET'));

        expect(
          File('${project.path}/lib/extensions/demo/demo_module.dart')
              .existsSync(),
          isTrue,
        );
        expect(
          File('${project.path}/test/extensions/demo/demo_module_test.dart')
              .existsSync(),
          isTrue,
        );
        expect(
          File('${project.path}/lib/extensions/demo/demo_module.dart')
              .readAsStringSync(),
          contains('Demo'),
        );

        final pubspec = File('${project.path}/pubspec.yaml').readAsStringSync();
        expect(pubspec, contains('demo_pkg: ^1.0.0'));

        final lock = LockfileStore(project).read();
        expect(lock.extensions['demo']?.version, '1.0.0');
        expect(
          lock.extensions['demo']?.files.keys,
          containsAll(<String>[
            'lib/extensions/demo/demo_module.dart',
            'test/extensions/demo/demo_module_test.dart',
          ]),
        );
        expect(
          lock.extensions['demo']?.patches,
          contains('android.permission.INTERNET'),
        );

        final codegen = File('${project.path}/lib/extensions/extensions.g.dart')
            .readAsStringSync();
        expect(codegen, contains("import 'demo/demo_module.dart';"));
        expect(codegen, contains('DemoModule(),'));

        final androidManifest = File(
          '${project.path}/android/app/src/main/AndroidManifest.xml',
        ).readAsStringSync();
        expect(androidManifest, contains('android.permission.INTERNET'));

        final macosEntitlements = File(
          '${project.path}/macos/Runner/Release.entitlements',
        ).readAsStringSync();
        expect(
          macosEntitlements,
          contains('com.apple.security.network.client'),
        );

        expect(
          Directory('${project.path}/.kiln/backups').listSync(),
          isNotEmpty,
        );
      },
    );

    test('does not write anything on a dry run', () async {
      final installer = ExtensionInstaller(
        projectRoot: project,
        available: [_demoExtension()],
      );

      final result = await installer.add(
        requested: const ['demo'],
        project: const {'name': 'fresh_app'},
        options: const InstallOptions(dryRun: true, verify: false),
      );

      expect(result.dryRun, isNotNull);
      expect(result.dryRun!.hasConflicts, isFalse);
      expect(
        result.dryRun!.files.map((change) => change.path),
        contains('lib/extensions/demo/demo_module.dart'),
      );
      expect(
        File('${project.path}/lib/extensions/demo/demo_module.dart')
            .existsSync(),
        isFalse,
      );
      expect(File('${project.path}/kiln.lock.yaml').existsSync(), isFalse);
      expect(
        File('${project.path}/pubspec.yaml').readAsStringSync(),
        isNot(contains('demo_pkg')),
      );
    });

    test('stops when a user-edited file conflicts', () async {
      final target = File(
        '${project.path}/lib/extensions/demo/demo_module.dart',
      );
      await target.parent.create(recursive: true);
      await target.writeAsString('// user content');

      final installer = ExtensionInstaller(
        projectRoot: project,
        available: [_demoExtension()],
      );

      final result = await installer.add(
        requested: const ['demo'],
        project: const {'name': 'fresh_app'},
        options: const InstallOptions(
          verify: false,
          collisionPolicy: CollisionPolicy.ask,
        ),
      );

      expect(result.hasConflicts, isTrue);
      expect(result.success, isFalse);
      expect(target.readAsStringSync(), '// user content');
      expect(File('${project.path}/kiln.lock.yaml').existsSync(), isFalse);
    });

    test(
      'reports an already installed extension without writing again',
      () async {
        final installer = ExtensionInstaller(
          projectRoot: project,
          available: [_demoExtension()],
        );
        await installer.add(
          requested: const ['demo'],
          project: const {'name': 'fresh_app'},
          options: const InstallOptions(verify: false),
        );

        final result = await installer.add(
          requested: const ['demo'],
          project: const {'name': 'fresh_app'},
          options: const InstallOptions(verify: false),
        );

        expect(result.plan.added, isEmpty);
        expect(result.warnings.join(), contains('already installed'));
        expect(result.changes, isEmpty);
      },
    );

    test('runs the verifier after a successful install', () async {
      var verifierCalls = 0;
      final installer = ExtensionInstaller(
        projectRoot: project,
        available: [_demoExtension()],
        verifier: Verifier(
          runner: (executable, arguments, workingDirectory) async {
            verifierCalls++;
            return ProcessResult(0, 0, 'ok', '');
          },
        ),
      );

      final result = await installer.add(
        requested: const ['demo'],
        project: const {'name': 'fresh_app'},
      );

      expect(verifierCalls, 2);
      expect(result.verification?.isSuccess, isTrue);
    });
  });

  group('ExtensionInstaller documentation', () {
    late Directory project;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    AvailableExtension documentedExtension() {
      return makeExtension(
        id: 'demo',
        name: 'Demo',
        provides: const ['demo'],
        dependencies: const {'demo_pkg': '^1.0.0'},
        docs: <String, List<int>>{
          'README.md': utf8.encode('# Demo\n\nEvery feature the app can use.\n'),
          'docs/usage.md': utf8.encode('# Usage\n'),
        },
      );
    }

    ExtensionInstaller installer() {
      return ExtensionInstaller(
        projectRoot: project,
        available: [documentedExtension()],
      );
    }

    test('installs the README and docs next to the extension code', () async {
      final result = await installer().add(
        requested: const ['demo'],
        project: const {'name': 'fresh_app'},
        options: const InstallOptions(verify: false),
      );

      expect(result.hasConflicts, isFalse);
      final readme = File('${project.path}/lib/extensions/demo/README.md');
      expect(readme.existsSync(), isTrue);
      expect(readme.readAsStringSync(), contains('Every feature'));
      expect(
        File('${project.path}/lib/extensions/demo/docs/usage.md').existsSync(),
        isTrue,
      );
      expect(
        LockfileStore(project).read().extensions['demo']?.files.keys,
        containsAll(<String>[
          'lib/extensions/demo/README.md',
          'lib/extensions/demo/docs/usage.md',
        ]),
      );
    });

    test('remove deletes the installed docs', () async {
      final adder = installer();
      await adder.add(
        requested: const ['demo'],
        project: const {'name': 'fresh_app'},
        options: const InstallOptions(verify: false),
      );

      await adder.remove(id: 'demo');

      expect(
        File('${project.path}/lib/extensions/demo/README.md').existsSync(),
        isFalse,
      );
      expect(
        File('${project.path}/lib/extensions/demo/docs/usage.md').existsSync(),
        isFalse,
      );
    });

    test('store extensions read docs from the extension root', () async {
      final root = await newTempDirectory('kiln_ext_docs_');
      File('${root.path}/README.md').writeAsStringSync('# Root readme');
      Directory('${root.path}/docs').createSync();
      File('${root.path}/docs/guide.md').writeAsStringSync('# Guide');
      addTearDown(() => root.delete(recursive: true));
      final installer = ExtensionInstaller(
        projectRoot: project,
        available: [
          AvailableExtension(
            manifest: ExtensionManifest(
              id: 'demo',
              name: 'Demo',
              version: '1.0.0',
              description: 'Extension demo for tests',
              category: 'tooling',
              provides: const ['demo'],
              dependencies: const {'demo_pkg': '^1.0.0'},
              rootPath: root.path,
            ),
            bundle: MasonBundle(
              name: 'demo',
              description: 'demo bundle',
              version: '1.0.0',
            ),
          ),
        ],
      );

      await installer.add(
        requested: const ['demo'],
        project: const {'name': 'fresh_app'},
        options: const InstallOptions(verify: false),
      );

      expect(
        File('${project.path}/lib/extensions/demo/README.md')
            .readAsStringSync(),
        contains('Root readme'),
      );
      expect(
        File('${project.path}/lib/extensions/demo/docs/guide.md').existsSync(),
        isTrue,
      );
    });
  });

  group('ExtensionInstaller.remove', () {
    late Directory project;
    late ExtensionInstaller installer;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
      installer = ExtensionInstaller(
        projectRoot: project,
        available: [_demoExtension()],
      );
      await installer.add(
        requested: const ['demo'],
        project: const {'name': 'fresh_app'},
        options: const InstallOptions(verify: false),
      );
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('removes owned files, dependency, patches, and lock entry', () async {
      final result = await installer.remove(id: 'demo');

      expect(result.deletedFiles, isNotEmpty);
      expect(
        File('${project.path}/lib/extensions/demo/demo_module.dart')
            .existsSync(),
        isFalse,
      );
      expect(
        File('${project.path}/test/extensions/demo/demo_module_test.dart')
            .existsSync(),
        isFalse,
      );
      expect(
        File('${project.path}/pubspec.yaml').readAsStringSync(),
        isNot(contains('demo_pkg')),
      );
      expect(
        File('${project.path}/android/app/src/main/AndroidManifest.xml')
            .readAsStringSync(),
        isNot(contains('android.permission.INTERNET')),
      );
      expect(
        File('${project.path}/macos/Runner/Release.entitlements')
            .readAsStringSync(),
        isNot(contains('com.apple.security.network.client')),
      );
      expect(LockfileStore(project).read().extensions, isEmpty);
      expect(
        File('${project.path}/lib/extensions/extensions.g.dart')
            .readAsStringSync(),
        isNot(contains('DemoModule')),
      );
    });

    test('skips edited files', () async {
      final target = File(
        '${project.path}/lib/extensions/demo/demo_module.dart',
      );
      await target.writeAsString('// edited by user');

      final result = await installer.remove(id: 'demo');
      expect(
        result.skippedFiles,
        contains('lib/extensions/demo/demo_module.dart'),
      );
      expect(
        result.warnings,
        contains(
          'Skipped "lib/extensions/demo/demo_module.dart": the file was '
          'edited or has no hash',
        ),
      );
      expect(target.existsSync(), isTrue);
    });

    test('force removes edited files', () async {
      final target = File(
        '${project.path}/lib/extensions/demo/demo_module.dart',
      );
      await target.writeAsString('// edited by user');

      final result = await installer.remove(
        id: 'demo',
        options: const RemoveOptions(force: true),
      );
      expect(target.existsSync(), isFalse);
      expect(result.warnings, contains(contains('because --force was used')));
    });

    test('protects an extension that others depend on', () async {
      final dependent = makeExtension(
        id: 'dependent',
        requires: const ['demo'],
      );
      final withDependent = ExtensionInstaller(
        projectRoot: project,
        available: [_demoExtension(), dependent],
      );
      await withDependent.add(
        requested: const ['dependent'],
        project: const {'name': 'fresh_app'},
        options: const InstallOptions(verify: false),
      );

      expect(
        () => withDependent.remove(id: 'demo'),
        throwsA(
          isA<KilnException>().having(
            (error) => error.code,
            'code',
            'remove.dependents',
          ),
        ),
      );
    });

    test('a dry run reports changes without writing', () async {
      final result = await installer.remove(
        id: 'demo',
        options: const RemoveOptions(dryRun: true),
      );

      expect(result.dryRun, isNotNull);
      expect(result.deletedFiles, isNotEmpty);
      expect(
        File('${project.path}/lib/extensions/demo/demo_module.dart')
            .existsSync(),
        isTrue,
      );
      expect(LockfileStore(project).read().extensions, isNotEmpty);
    });
  });

  group('ExtensionInstaller conditional native setup', () {
    late Directory project;

    setUp(() async {
      project = await copyProjectFixture('fresh_app');
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('applies and reverts patches from saved answers', () async {
      final extension = makeExtension(
        id: 'conditional',
        platformSetup: const PlatformSetup(
          android: AndroidSetup(permissions: ['android.permission.INTERNET']),
          conditionals: [
            NativeConditionalSetup(
              when: {'exact_alarms': true},
              android: AndroidSetup(
                permissions: ['android.permission.SCHEDULE_EXACT_ALARM'],
              ),
            ),
          ],
        ),
        bundle: bundleFromFixture('tiny_brick'),
      );
      final installer = ExtensionInstaller(
        projectRoot: project,
        available: [extension],
      );
      final manifestFile = File(
        '${project.path}/android/app/src/main/AndroidManifest.xml',
      );

      await installer.add(
        requested: const ['conditional'],
        project: const {'name': 'fresh_app'},
        answers: const {
          'conditional': {'exact_alarms': true},
        },
        options: const InstallOptions(
          verify: false,
          collisionPolicy: CollisionPolicy.ask,
        ),
      );

      expect(
        manifestFile.readAsStringSync(),
        contains('android.permission.SCHEDULE_EXACT_ALARM'),
      );
      expect(
        LockfileStore(project).read().extensions['conditional']!.patches,
        contains('android.permission.SCHEDULE_EXACT_ALARM'),
      );

      await installer.remove(
        id: 'conditional',
        answers: const {'exact_alarms': true},
      );

      expect(
        manifestFile.readAsStringSync(),
        isNot(contains('android.permission.SCHEDULE_EXACT_ALARM')),
      );
    });
  });
}
