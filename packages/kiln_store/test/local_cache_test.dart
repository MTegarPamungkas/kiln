import 'dart:convert';
import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late LocalCache cache;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('kiln_store_cache_');
    cache = LocalCache(Directory(p.join(temp.path, 'cache')),
      registry: RegistryConfig(url: 'https://example.com/registry'),
    );
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  group('LocalCache', () {
    test('places the index and archives in a stable layout', () {
      expect(p.basename(cache.indexFile.path), 'index.json');
      expect(
        p.relative(
          cache.archiveFile('demo_ext', '1.0.0').path,
          from: cache.root.path,
        ),
        p.join('archives', '${sha256Hex(utf8.encode(jsonEncode(['demo_ext', '1.0.0'])))}.tgz'),
      );
    });

    test('returns null when nothing is cached', () async {
      expect(await cache.readIndex(), isNull);
      expect(await cache.readArchive('demo_ext', '1.0.0'), isNull);
    });

    test('writes and reads the registry index', () async {
      final index = _index();

      cache.writeIndex(index);

      expect(cache.indexFile.existsSync(), isTrue);
      final loaded = await cache.readIndex();
      expect(loaded, isNotNull);
      expect(loaded!.generatedAt, index.generatedAt);
      expect(loaded.extensions.single.id, 'demo_ext');
      expect(loaded.extensions.single.versions.single.sha256, 'a' * 64);
    });

    test('writes, reads, and replaces archives', () async {
      final first = utf8.encode('first archive');
      final second = utf8.encode('second archive');

      cache.writeArchive('demo_ext', '1.0.0', first);
      expect(await cache.readArchive('demo_ext', '1.0.0'), first);

      cache.writeArchive('demo_ext', '1.0.0', second);
      expect(await cache.readArchive('demo_ext', '1.0.0'), second);
      expect(
        cache.archiveFile('demo_ext', '1.0.0').lengthSync(),
        second.length,
      );
    });

    test('keeps archives for different versions separate', () async {
      cache.writeArchive('demo_ext', '1.0.0', utf8.encode('one'));
      cache.writeArchive('demo_ext', '2.0.0', utf8.encode('two'));

      expect(await cache.readArchive('demo_ext', '1.0.0'), utf8.encode('one'));
      expect(await cache.readArchive('demo_ext', '2.0.0'), utf8.encode('two'));
    });

    test('clear removes the index and archives and keeps the root', () async {
      cache.writeIndex(_index());
      cache.writeArchive('demo_ext', '1.0.0', utf8.encode('archive'));

      cache.clear();

      expect(cache.root.existsSync(), isTrue);
      expect(cache.indexFile.existsSync(), isFalse);
      expect(cache.archiveFile('demo_ext', '1.0.0').existsSync(), isFalse);
      expect(await cache.readIndex(), isNull);
    });
  });
}

RegistryIndex _index() {
  return RegistryIndex(
    generatedAt: DateTime.utc(2026, 2, 1, 12),
    extensions: [
      RegistryExtension(
        id: 'demo_ext',
        name: 'Demo',
        description: 'Demo extension',
        category: 'testing',
        latest: '1.0.0',
        tier: ExtensionTier.verified,
        versions: [
          RegistryVersion(
            version: '1.0.0',
            url: 'archives/demo_ext-1.0.0.tgz',
            sha256: 'a' * 64,
          ),
        ],
      ),
    ],
  );
}
