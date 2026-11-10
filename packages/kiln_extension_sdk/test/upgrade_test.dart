import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:mason/mason.dart' show MasonBundle, createBundle;
import 'package:test/test.dart';

import 'support/fixtures.dart';

MasonBundle _bundle(Map<String, String> files) {
  final directory = Directory.systemTemp.createTempSync('kiln_upgrade_brick_');
  try {
    File('${directory.path}/brick.yaml').writeAsStringSync('''
name: demo
description: Demo upgrade brick
version: 2.0.0
vars:
  id:
    type: string
    default: demo
  name:
    type: string
    default: Demo
''');
    for (final file in files.entries) {
      final target = File('${directory.path}/__brick__/${file.key}');
      target.parent.createSync(recursive: true);
      target.writeAsStringSync(file.value);
    }
    return createBundle(directory);
  } finally {
    directory.deleteSync(recursive: true);
  }
}

AvailableExtension _version(
  String version, {
  MasonBundle? bundle,
  Map<String, Object?> dependencies = const <String, Object?>{},
}) => makeExtension(
  id: 'demo',
  name: 'Demo',
  version: version,
  provides: const <String>['demo'],
  dependencies: dependencies,
  bundle: bundle ?? bundleFromFixture('tiny_brick'),
);

Verifier _verifier({required bool succeeds}) => Verifier(
  runner: (executable, arguments, workingDirectory) async =>
      ProcessResult(succeeds ? 0 : 1, succeeds ? 0 : 1, '', ''),
);

Future<(Directory, LockfileStore)> _installedV1() async {
  final project = await copyProjectFixture('fresh_app');
  final installer = ExtensionInstaller(
    projectRoot: project,
    available: [
      _version('1.0.0', dependencies: const {'demo_pkg': '^1.0.0'}),
    ],
  );
  final result = await installer.add(
    requested: const ['demo'],
    project: const {'name': 'fresh_app'},
    options: const InstallOptions(verify: false),
  );
  expect(result.success, isTrue);
  return (project, LockfileStore(project));
}

void main() {
  test('upgrade stages everything and publishes one verified transaction', () async {
    final (project, locks) = await _installedV1();
    try {
      final v2 = _version(
        '2.0.0',
        dependencies: const {'demo_pkg': '^1.0.0'},
        bundle: _bundle(const {
          'lib/extensions/demo/demo_module.dart': '// upgraded module\n',
        }),
      );
      final installer = ExtensionInstaller(
        projectRoot: project,
        available: [v2],
        verifier: _verifier(succeeds: true),
      );

      final result = await installer.upgrade(
        id: 'demo',
        project: const {'name': 'fresh_app', 'org': 'com.example'},
        options: const InstallOptions(verify: true),
      );

      expect(result.hasConflicts, isFalse);
      expect(result.success, isTrue);
      expect(
        File('${project.path}/lib/extensions/demo/demo_module.dart')
            .readAsStringSync(),
        '// upgraded module\n',
      );
      expect(locks.read().extensions['demo']?.version, '2.0.0');
    } finally {
      await project.delete(recursive: true);
    }
  });

  test('a new generated file never overwrites a user file without force', () async {
    final (project, locks) = await _installedV1();
    try {
      final userFile = File('${project.path}/lib/extensions/demo/new_file.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// user work\n');
      final oldModule = File(
        '${project.path}/lib/extensions/demo/demo_module.dart',
      ).readAsStringSync();
      final v2 = _version(
        '2.0.0',
        bundle: _bundle(const {
          'lib/extensions/demo/demo_module.dart': '// upgraded module\n',
          'lib/extensions/demo/new_file.dart': '// generated file\n',
        }),
      );
      final installer = ExtensionInstaller(
        projectRoot: project,
        available: [v2],
        verifier: _verifier(succeeds: true),
      );

      final result = await installer.upgrade(
        id: 'demo',
        project: const {'name': 'fresh_app'},
        options: const InstallOptions(verify: false),
      );

      expect(result.hasConflicts, isTrue);
      expect(userFile.readAsStringSync(), '// user work\n');
      expect(
        File('${project.path}/lib/extensions/demo/demo_module.dart')
            .readAsStringSync(),
        oldModule,
      );
      expect(locks.read().extensions['demo']?.version, '1.0.0');
    } finally {
      await project.delete(recursive: true);
    }
  });

  test('force replaces the user file only when requested', () async {
    final (project, _) = await _installedV1();
    try {
      final userFile = File('${project.path}/lib/extensions/demo/new_file.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('// user work\n');
      final v2 = _version(
        '2.0.0',
        bundle: _bundle(const {
          'lib/extensions/demo/demo_module.dart': '// upgraded module\n',
          'lib/extensions/demo/new_file.dart': '// generated file\n',
        }),
      );
      final installer = ExtensionInstaller(
        projectRoot: project,
        available: [v2],
        verifier: _verifier(succeeds: true),
      );

      final result = await installer.upgrade(
        id: 'demo',
        project: const {'name': 'fresh_app'},
        force: true,
        options: const InstallOptions(verify: false),
      );

      expect(result.success, isTrue);
      expect(userFile.readAsStringSync(), '// generated file\n');
    } finally {
      await project.delete(recursive: true);
    }
  });

  test('a verification failure restores every managed file and the lockfile', () async {
    final (project, locks) = await _installedV1();
    try {
      final before = {
        for (final path in <String>[
          'lib/extensions/demo/demo_module.dart',
          'test/extensions/demo/demo_module_test.dart',
          'pubspec.yaml',
          'kiln.lock.yaml',
          'lib/extensions/extensions.g.dart',
        ])
          path: File('${project.path}/$path').readAsStringSync(),
      };
      final v2 = _version(
        '2.0.0',
        dependencies: const {'demo_pkg': '^1.0.0'},
        bundle: _bundle(const {
          'lib/extensions/demo/demo_module.dart': '// broken upgrade\n',
        }),
      );
      final installer = ExtensionInstaller(
        projectRoot: project,
        available: [v2],
        verifier: _verifier(succeeds: false),
      );

      final result = await installer.upgrade(
        id: 'demo',
        project: const {'name': 'fresh_app'},
        options: const InstallOptions(verify: true),
      );

      expect(result.success, isFalse);
      expect(result.verification?.isSuccess, isFalse);
      for (final entry in before.entries) {
        expect(
          File('${project.path}/${entry.key}').readAsStringSync(),
          entry.value,
          reason: entry.key,
        );
      }
      expect(locks.read().extensions['demo']?.version, '1.0.0');
    } finally {
      await project.delete(recursive: true);
    }
  });

  test('upgrade refuses to replace files edited by the user', () async {
    final (project, _) = await _installedV1();
    try {
      final module = File(
        '${project.path}/lib/extensions/demo/demo_module.dart',
      )..writeAsStringSync('// edited by the user\n');
      final v2 = _version(
        '2.0.0',
        bundle: _bundle(const {
          'lib/extensions/demo/demo_module.dart': '// upgraded module\n',
        }),
      );
      final installer = ExtensionInstaller(
        projectRoot: project,
        available: [v2],
        verifier: _verifier(succeeds: true),
      );

      await expectLater(
        installer.upgrade(
          id: 'demo',
          project: const {'name': 'fresh_app'},
          options: const InstallOptions(verify: false),
        ),
        throwsA(isA<KilnException>().having((error) => error.code, 'code', 'upgrade.conflict')),
      );
      expect(module.readAsStringSync(), '// edited by the user\n');
    } finally {
      await project.delete(recursive: true);
    }
  });
}
