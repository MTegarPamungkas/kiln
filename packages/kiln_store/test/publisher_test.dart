import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late Directory registry;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('kiln_store_publish_');
    registry = Directory(p.join(temp.path, 'registry'));
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  group('Publisher', () {
    test('validates, packs, and updates the registry index', () async {
      final extension = _createExtension(temp, id: 'demo_ext');

      final result = await Publisher().publish(
        extensionRoot: extension,
        registryRoot: registry,
      );

      final archive = File(result.archivePath);
      final indexFile = File(result.indexPath);
      expect(archive.existsSync(), isTrue);
      expect(
        p.relative(archive.path, from: registry.path),
        p.join('archives', 'demo_ext-1.0.0.tgz'),
      );
      expect(result.sha256, sha256Hex(archive.readAsBytesSync()));
      expect(indexFile.existsSync(), isTrue);

      final index = RegistryIndex.parse(indexFile.readAsStringSync());
      final published = index.find('demo_ext')!;
      expect(published.name, 'Demo Extension');
      expect(published.description, 'Demo extension for publisher tests.');
      expect(published.category, 'testing');
      expect(published.tier, ExtensionTier.community);
      expect(published.latest, '1.0.0');
      expect(published.versions, hasLength(1));
      expect(published.versions.single.url, 'archives/demo_ext-1.0.0.tgz');
      expect(published.versions.single.sha256, result.sha256);
      expect(published.versions.single.provides, ['demo']);
      expect(published.versions.single.compatibility['kiln'], '>=0.1.0 <0.3.0');
    });

    test('preserves other extensions and sorts ids and versions', () async {
      final first = _createExtension(temp, id: 'demo_a');
      _createExtension(temp, id: 'demo_b');

      await Publisher().publish(extensionRoot: first, registryRoot: registry);
      await Publisher().publish(
        extensionRoot: _createExtension(temp, id: 'demo_a', version: '1.1.0'),
        registryRoot: registry,
      );
      await Publisher().publish(
        extensionRoot: Directory(p.join(temp.path, 'demo_b')),
        registryRoot: registry,
      );

      final index = RegistryIndex.parse(
        File(p.join(registry.path, 'index.json')).readAsStringSync(),
      );

      expect(index.extensions.map((extension) => extension.id), [
        'demo_a',
        'demo_b',
      ]);
      expect(index.find('demo_a')!.versions.map((version) => version.version), [
        '1.0.0',
        '1.1.0',
      ]);
      expect(index.find('demo_a')!.latest, '1.1.0');
      expect(index.find('demo_b')!.latest, '1.0.0');
    });

    test('refuses a duplicate version unless forced', () async {
      final extension = _createExtension(temp, id: 'demo_ext');
      final publisher = Publisher();
      await publisher.publish(extensionRoot: extension, registryRoot: registry);
      final before = File(p.join(registry.path, 'index.json'))
          .readAsStringSync();

      await expectLater(
        publisher.publish(extensionRoot: extension, registryRoot: registry),
        throwsA(
          isA<KilnStoreException>()
              .having((error) => error.code, 'code', 'store.duplicate_version')
              .having((error) => error.details['id'], 'id', 'demo_ext')
              .having((error) => error.details['version'], 'version', '1.0.0'),
        ),
      );

      expect(
        File(p.join(registry.path, 'index.json')).readAsStringSync(),
        before,
      );
    });

    test('force replaces the archive and the index entry', () async {
      final extension = _createExtension(temp, id: 'demo_ext');
      final publisher = Publisher();
      final first = await publisher.publish(
        extensionRoot: extension,
        registryRoot: registry,
      );
      File(p.join(extension.path, 'extra.txt')).writeAsStringSync('changed');

      final second = await publisher.publish(
        extensionRoot: extension,
        registryRoot: registry,
        force: true,
      );

      expect(second.sha256, isNot(first.sha256));
      expect(File(second.archivePath).lengthSync(), greaterThan(0));
      final index = RegistryIndex.parse(
        File(p.join(registry.path, 'index.json')).readAsStringSync(),
      );
      expect(index.find('demo_ext')!.versions, hasLength(1));
      expect(index.find('demo_ext')!.versions.single.sha256, second.sha256);
      expect(
        sha256Hex(File(second.archivePath).readAsBytesSync()),
        second.sha256,
      );
    });

    test('uses an archive base URL when provided', () async {
      final extension = _createExtension(temp, id: 'demo_ext');

      final result = await Publisher().publish(
        extensionRoot: extension,
        registryRoot: registry,
        archiveBaseUrl: Uri.parse('https://cdn.example.com/kiln'),
      );

      final index = RegistryIndex.parse(
        File(result.indexPath).readAsStringSync(),
      );
      expect(
        index.find('demo_ext')!.versions.single.url,
        'https://cdn.example.com/kiln/archives/demo_ext-1.0.0.tgz',
      );
    });

    test('sets latest to the highest published version', () async {
      final publisher = Publisher();
      await publisher.publish(
        extensionRoot: _createExtension(temp, id: 'demo_ext'),
        registryRoot: registry,
      );
      await publisher.publish(
        extensionRoot: _createExtension(temp, id: 'demo_ext', version: '2.0.0'),
        registryRoot: registry,
      );

      final index = RegistryIndex.parse(
        File(p.join(registry.path, 'index.json')).readAsStringSync(),
      );
      expect(index.find('demo_ext')!.latest, '2.0.0');
      expect(index.find('demo_ext')!.versions.last.version, '2.0.0');
    });

    test('is deterministic across registries for identical content', () async {
      final extension = _createExtension(temp, id: 'demo_ext');
      final other = Directory(p.join(temp.path, 'other_registry'));

      final first = await Publisher().publish(
        extensionRoot: extension,
        registryRoot: registry,
      );
      final second = await Publisher().publish(
        extensionRoot: extension,
        registryRoot: other,
      );

      expect(first.sha256, second.sha256);
      expect(
        File(first.archivePath).readAsBytesSync(),
        File(second.archivePath).readAsBytesSync(),
      );
    });

    test('rejects an invalid manifest before writing', () async {
      final extension = _createExtension(
        temp,
        id: 'demo_ext',
        version: 'not-semver',
      );

      await expectLater(
        Publisher().publish(extensionRoot: extension, registryRoot: registry),
        throwsA(
          isA<KilnException>()
              .having((error) => error.code, 'code', 'manifest.invalid')
              .having(
                (error) => error.details['errors'],
                'errors',
                contains(contains('version must be semver')),
              ),
        ),
      );
      expect(
        Directory(p.join(registry.path, 'archives')).existsSync(),
        isFalse,
      );
      expect(File(p.join(registry.path, 'index.json')).existsSync(), isFalse);
    });

    test('reports a missing extension.yaml', () async {
      final empty = Directory(p.join(temp.path, 'empty'))..createSync();

      await expectLater(
        Publisher().publish(extensionRoot: empty, registryRoot: registry),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.manifest_missing',
          ),
        ),
      );
    });

    test('serialises a publish result', () async {
      final result = await Publisher().publish(
        extensionRoot: _createExtension(temp, id: 'demo_ext'),
        registryRoot: registry,
      );

      expect(result.toJson(), <String, Object?>{
        'id': 'demo_ext',
        'version': '1.0.0',
        'sha256': result.sha256,
        'archive': result.archivePath,
        'index': result.indexPath,
      });
    });
  });
}

Directory _createExtension(
  Directory temp, {
  required String id,
  String version = '1.0.0',
}) {
  final root = Directory(p.join(temp.path, id))..createSync(recursive: true);
  File(p.join(root.path, 'extension.yaml')).writeAsStringSync(
    'id: $id\n'
    'name: Demo Extension\n'
    'version: $version\n'
    'description: Demo extension for publisher tests.\n'
    'category: testing\n'
    'tier: community\n'
    'provides:\n'
    '  - demo\n'
    'compatibility:\n'
    '  kiln: ">=0.1.0 <0.3.0"\n',
  );
  final brick = File(p.join(root.path, 'brick', 'brick.yaml'));
  brick.parent.createSync(recursive: true);
  brick.writeAsStringSync('name: $id\n');
  return root;
}
