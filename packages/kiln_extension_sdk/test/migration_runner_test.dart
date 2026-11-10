import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('MigrationRunner', () {
    late Directory project;

    setUp(() async {
      project = await Directory.systemTemp.createTemp('kiln_migration_');
      await Directory('${project.path}/lib').create(recursive: true);
      await File('${project.path}/lib/old.dart').writeAsString('old');
      await File('${project.path}/lib/delete.dart').writeAsString('delete');
      await File('${project.path}/pubspec.yaml').writeAsString('''
name: demo
version: 1.0.0
dependencies:
  dio: ^5.0.0
''');
      await File('${project.path}/kiln.yaml').writeAsString('''
kiln: ">=0.2.0 <0.3.0"
core: ^0.1.0
project:
  name: demo
  org: com.example
''');
    });

    tearDown(() async {
      await project.delete(recursive: true);
    });

    test('applies actions in order and reports messages', () {
      const migration = Migration(
        version: 1,
        from: '0.1.0',
        to: '0.2.0',
        actions: [
          RenameFileAction(from: 'lib/old.dart', to: 'lib/new.dart'),
          DeleteFileAction('lib/delete.dart'),
          ReplaceDependencyAction(name: 'dio', version: '^5.9.0'),
          UpdateConfigAction(key: 'project.name', value: 'renamed'),
          MessageAction('Migration complete'),
        ],
      );

      final result = const MigrationRunner().run(
        projectRoot: project,
        migrations: const [migration],
      );

      expect(File('${project.path}/lib/new.dart').readAsStringSync(), 'old');
      expect(File('${project.path}/lib/old.dart').existsSync(), isFalse);
      expect(File('${project.path}/lib/delete.dart').existsSync(), isFalse);

      final pubspec = loadYaml(
        File('${project.path}/pubspec.yaml').readAsStringSync(),
      ) as YamlMap;
      expect((pubspec['dependencies'] as YamlMap)['dio'], '^5.9.0');

      final config = loadYaml(
        File('${project.path}/kiln.yaml').readAsStringSync(),
      ) as YamlMap;
      expect((config['project'] as YamlMap)['name'], 'renamed');

      expect(result.applied, ['0.1.0 -> 0.2.0']);
      expect(result.messages, ['Migration complete']);
    });

    test('rejects traversal and absolute paths before any change', () async {
      final sibling = File('${project.parent.path}/kiln-outside.txt')
        ..writeAsStringSync('do not touch');
      final unsafe = <String>[
        '../kiln-outside.txt',
        'lib/../../kiln-outside.txt',
        '/etc/passwd',
        'C:/Windows/System32/drivers/etc/hosts',
        r'lib\escape.dart',
        'lib/./escape.dart',
      ];
      try {
        for (final path in unsafe) {
          const firstAction = DeleteFileAction('lib/delete.dart');
          final migration = Migration(
            version: 1,
            from: '0.1.0',
            to: '0.2.0',
            actions: [firstAction, DeleteFileAction(path)],
          );
          expect(
            () => const MigrationRunner().run(
              projectRoot: project,
              migrations: [migration],
            ),
            throwsA(isA<KilnException>().having((e) => e.code, 'code', 'path.unsafe')),
            reason: path,
          );
          expect(
            File('${project.path}/lib/delete.dart').existsSync(),
            isTrue,
            reason: 'validation must happen before the first action: $path',
          );
          expect(sibling.existsSync(), isTrue);
        }
      } finally {
        await sibling.delete();
      }
    });

    test('rejects a rename destination outside the project', () async {
      final sibling = File('${project.parent.path}/kiln-rename.txt')
        ..writeAsStringSync('do not touch');
      try {
        const migration = Migration(
          version: 1,
          from: '0.1.0',
          to: '0.2.0',
          actions: [
            RenameFileAction(
              from: 'lib/old.dart',
              to: '../kiln-rename.txt',
            ),
          ],
        );
        expect(
          () => const MigrationRunner().run(
            projectRoot: project,
            migrations: const [migration],
          ),
          throwsA(isA<KilnException>()),
        );
        expect(File('${project.path}/lib/old.dart').existsSync(), isTrue);
        expect(sibling.readAsStringSync(), 'do not touch');
      } finally {
        await sibling.delete();
      }
    });

    test('rejects a path that traverses an existing symlink', () async {
      final outside = await Directory.systemTemp.createTemp('kiln_outside_');
      final link = Link('${project.path}/lib/link');
      try {
        try {
          await link.create(outside.path);
        } on FileSystemException {
          return; // Creating symlinks may require elevated rights.
        }
        final migration = Migration(
          version: 1,
          from: '0.1.0',
          to: '0.2.0',
          actions: [DeleteFileAction('lib/link/${File(outside.path).uri.pathSegments.last}')],
        );
        expect(
          () => const MigrationRunner().run(
            projectRoot: project,
            migrations: [migration],
          ),
          throwsA(isA<KilnException>()),
        );
      } finally {
        if (link.existsSync()) link.deleteSync();
        await outside.delete(recursive: true);
      }
    });

    test('rolls back when an action fails', () {
      const migration = Migration(
        version: 1,
        from: '0.1.0',
        to: '0.2.0',
        actions: [
          RenameFileAction(from: 'lib/old.dart', to: 'lib/new.dart'),
          RenameFileAction(from: 'lib/missing.dart', to: 'lib/never.dart'),
        ],
      );

      expect(
        () => const MigrationRunner().run(
          projectRoot: project,
          migrations: const [migration],
        ),
        returnsNormally,
      );
      // The missing source is a safe no-op, so the first rename stays.
      expect(File('${project.path}/lib/new.dart').existsSync(), isTrue);
    });
  });

  group('MigrationLoader', () {
    test('loads migrations sorted by their version number', () async {
      final root = await Directory.systemTemp.createTemp('kiln_migrations_');
      final migrations = Directory('${root.path}/migrations')
        ..createSync(recursive: true);
      File('${migrations.path}/2.yaml').writeAsStringSync('''
version: 2
from: 0.2.0
to: 0.3.0
actions: []
''');
      File('${migrations.path}/1.yaml').writeAsStringSync('''
version: 1
from: 0.1.0
to: 0.2.0
actions: []
''');

      final loaded = const MigrationLoader().load(root);
      expect(loaded.map((migration) => migration.version), [1, 2]);

      final selected = const MigrationLoader().select(
        migrations: loaded,
        installed: '0.1.0',
        target: '0.3.0',
      );
      expect(selected, hasLength(2));
      await root.delete(recursive: true);
    });
  });
}
