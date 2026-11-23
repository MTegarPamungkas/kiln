import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../support/cli_support.dart';

Future<Directory> _registry() async {
  return Directory.systemTemp.createTemp('kiln_registry_');
}

Future<Directory> _extension(
  String version,
  String marker, {
  String id = 'demo_ext',
  String capability = 'demo',
  String? requires,
  String? dart,
  String? flutter,
}) async {
  final root = await Directory.systemTemp.createTemp('kiln_demo_ext_');
  await File(p.join(root.path, 'extension.yaml')).writeAsString('''
id: $id
name: Demo extension
version: $version
description: Demo extension for store tests.
category: testing
tier: official
provides:
  - $capability
${requires == null ? '' : 'requires:\n  - $requires'}
compatibility:
  kiln: ">=0.1.0 <0.2.0"
${dart == null ? '' : '  dart: "$dart"'}
${flutter == null ? '' : '  flutter: "$flutter"'}
''');
  await File(p.join(root.path, 'brick', 'brick.yaml')).create(recursive: true);
  await File(p.join(root.path, 'brick', 'brick.yaml')).writeAsString('''
name: $id
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
      id,
      '${id}_module.dart',
    ),
  );
  await module.parent.create(recursive: true);
  await module.writeAsString('''
import 'package:kiln_core/kiln_core.dart';

final class ${id.split('_').map((part) => part[0].toUpperCase() + part.substring(1)).join()}Module extends KilnModule {
  const ${id.split('_').map((part) => part[0].toUpperCase() + part.substring(1)).join()}Module();

  @override
  String get id => '$id';

  @override
  Set<String> get provides => const <String>{'$capability'};
${requires == null ? '' : "  @override\n  Set<String> get requires => const <String>{'$requires'};"}

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

    test('installs and maintains registry extensions alongside a bundled extension', () async {
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(await runner.run(['add', 'l10n', '--no-verify', '--yes']), 0);

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
      expect(lock.ids, containsAll(['demo_ext', 'l10n']));
      expect(lock.extensions['demo_ext']?.artifact?.sha256, hasLength(64));
      expect(await runner.run(['setup', 'demo_ext', '--dry-run', '--yes']), 0);
      expect(await runner.run(['repair', 'demo_ext', '--dry-run', '--yes']), 0);
      expect(await runner.run(['rollback']), 0);
      expect(LockfileStore(project).read().ids, {'l10n'});
    });

    test('loads a registry-only capability dependency', () async {
      final consumer = await _extension(
        '0.1.0',
        'consumer',
        id: 'demo_consumer',
        capability: 'consumer',
        requires: 'demo',
      );
      addTearDown(() => consumer.delete(recursive: true));
      await Publisher().publish(
        extensionRoot: consumer,
        registryRoot: registry,
      );
      final runner = buildTestRunner(cwd: project, captured: captured);
      expect(
        await runner.run([
          'store',
          'install',
          'demo_consumer',
          '--no-verify',
          '--yes',
        ]),
        0,
        reason: captured.err.join('\n'),
      );
      expect(LockfileStore(project).read().ids, {'demo_consumer', 'demo_ext'});
    });

    test(
      'checks explicit versions and falls back to a compatible version',
      () async {
        final incompatible = await _extension(
          '0.2.0',
          'future',
          dart: '>=99.0.0',
          flutter: '>=99.0.0',
        );
        addTearDown(() => incompatible.delete(recursive: true));
        await Publisher().publish(
          extensionRoot: incompatible,
          registryRoot: registry,
        );
        final runner = buildTestRunner(
          cwd: project,
          captured: captured,
          processRunner: FakeProcessRunner(
            (_, _, _) async =>
                ProcessResult(0, 0, '{"frameworkVersion":"3.47.9"}', ''),
          ),
        );
        expect(
          await runner.run([
            'store',
            'install',
            'demo_ext',
            '--version',
            '0.2.0',
            '--no-verify',
            '--yes',
          ]),
          isNot(0),
        );
        expect(LockfileStore(project).read().ids, isEmpty);
        expect(
          await runner.run([
            'store',
            'install',
            'demo_ext',
            '--no-verify',
            '--yes',
          ]),
          0,
          reason: captured.err.join('\n'),
        );
        expect(
          LockfileStore(project).read().extensions['demo_ext']?.version,
          '0.1.0',
        );
      },
    );

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
      await Publisher().publish(extensionRoot: next, registryRoot: registry);
      captured.clear();

      final code = await runner.run(<String>[
        'upgrade',
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
          File(p.join(registry.path, 'archives', 'demo_ext-0.1.0.tgz'))
              .existsSync(),
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
