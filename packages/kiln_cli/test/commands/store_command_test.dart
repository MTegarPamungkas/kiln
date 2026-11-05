import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

Future<Directory> _registry() async {
  return Directory.systemTemp.createTemp('kiln_registry_');
}

Future<Directory> _extension(String version, String marker) async {
  final root = await Directory.systemTemp.createTemp('kiln_demo_ext_');
  await File(p.join(root.path, 'extension.yaml')).writeAsString('''
id: demo_ext
name: Demo extension
version: $version
description: Demo extension for store tests.
category: testing
tier: official
provides:
  - demo
compatibility:
  kiln: ">=0.1.0 <0.2.0"
''');
  await File(p.join(root.path, 'brick', 'brick.yaml'))
      .create(recursive: true);
  await File(p.join(root.path, 'brick', 'brick.yaml')).writeAsString('''
name: demo_ext
description: Demo brick.
version: $version
environment:
  mason: ">=0.1.0 <0.2.0"
''');
  final module = File(
    p.join(
      root.path,
      'brick',
      '__brick__',
      'lib',
      'extensions',
      'demo_ext',
      'demo_ext_module.dart',
    ),
  );
  await module.parent.create(recursive: true);
  await module.writeAsString('''
import 'package:kiln_core/kiln_core.dart';

final class DemoExtModule extends KilnModule {
  const DemoExtModule();

  @override
  String get id => 'demo_ext';

  @override
  Set<String> get provides => const <String>{'demo'};

  @override
  void register(Registry registry) {}
}

const demoMarker = '$marker';
''');
  return root;
}

Future<Directory> _projectWithRegistry(String registryPath) async {
  final project = await createTempProject();
  await File(p.join(project.path, 'kiln.yaml')).writeAsString(
    '${File(p.join(project.path, 'kiln.yaml')).readAsStringSync()}'
    "registry:\n  url: '$registryPath'\n",
  );
  return project;
}

void main() {
  group('kiln store', () {
    late Directory registry;
    late Directory extension;
    late Directory project;
    late CapturedLogger captured;

    setUp(() async {
      registry = await _registry();
      extension = await _extension('0.1.0', 'v1');
      await Publisher().publish(
        extensionRoot: extension,
        registryRoot: registry,
      );
      project = await _projectWithRegistry(registry.path);
      captured = CapturedLogger();
    });

    tearDown(() async {
      for (final directory in <Directory>[registry, extension, project]) {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      }
    });

    test('searches and inspects the registry index', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      expect(await runner.run(<String>['store', 'search', 'demo']), 0);
      expect(captured.out.join('\n'), contains('demo_ext'));

      captured.clear();
      expect(await runner.run(<String>['store', 'info', 'demo_ext']), 0);
      expect(captured.out.join('\n'), contains('0.1.0'));
    });

    test('installs an extension from the registry', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'store',
        'install',
        'demo_ext',
        '--no-verify',
        '--yes',
      ]);

      expect(code, 0, reason: captured.err.join('\n'));
      expect(
        File(
          p.join(
            project.path,
            'lib',
            'extensions',
            'demo_ext',
            'demo_ext_module.dart',
          ),
        ).readAsStringSync(),
        contains('v1'),
      );
      final lock = LockfileStore(project).read();
      expect(lock.ids, contains('demo_ext'));
    });

    test('rejects a missing version', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);

      final code = await runner.run(<String>[
        'store',
        'install',
        'demo_ext',
        '--version',
        '9.9.9',
        '--yes',
      ]);

      expect(code, isNot(0));
      expect(captured.err.join('\n'), contains('9.9.9'));
    });

    test('upgrades to a newer registry version', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(
        await runner.run(<String>[
          'store',
          'install',
          'demo_ext',
          '--no-verify',
          '--yes',
        ]),
        0,
      );

      final next = await _extension('0.2.0', 'v2');
      final migration = File(
        p.join(next.path, 'migrations', '0.1.0-0.2.0.yaml'),
      );
      await migration.parent.create(recursive: true);
      await migration.writeAsString('''
version: 1
from: 0.1.0
to: 0.2.0
actions:
  - type: message
    text: migrated demo_ext
''');
      await Publisher().publish(
        extensionRoot: next,
        registryRoot: registry,
      );
      captured.clear();

      final code = await runner.run(<String>['upgrade', '--no-verify', '--yes']);

      expect(code, 0, reason: captured.err.join('\n'));
      expect(
        File(
          p.join(
            project.path,
            'lib',
            'extensions',
            'demo_ext',
            'demo_ext_module.dart',
          ),
        ).readAsStringSync(),
        contains('v2'),
      );
      expect(captured.out.join('\n'), contains('0.1.0'));
      await next.delete(recursive: true);
    });
  });

  group('kiln ext publish', () {
    test('publishes to a local registry and supports dry runs', () async {
      final registry = await _registry();
      final extension = await _extension('0.1.0', 'v1');
      final project = await createTempProject();
      final captured = CapturedLogger();
      final runner = buildTestRunner(cwd: project, captured: captured);

      try {
        final code = await runner.run(<String>[
          'ext',
          'publish',
          extension.path,
          '--registry',
          registry.path,
          '--json',
        ]);
        expect(code, 0, reason: captured.err.join('\n'));
        expect(File(p.join(registry.path, 'index.json')).existsSync(), isTrue);
        expect(
          File(
            p.join(registry.path, 'archives', 'demo_ext-0.1.0.tgz'),
          ).existsSync(),
          isTrue,
        );

        final emptyRegistry = await _registry();
        captured.clear();
        expect(
          await runner.run(<String>[
            'ext',
            'publish',
            extension.path,
            '--registry',
            emptyRegistry.path,
            '--dry-run',
          ]),
          0,
        );
        expect(
          File(p.join(emptyRegistry.path, 'index.json')).existsSync(),
          isFalse,
        );
        await emptyRegistry.delete(recursive: true);
      } finally {
        await registry.delete(recursive: true);
        await extension.delete(recursive: true);
        await project.delete(recursive: true);
      }
    });
  });
}
