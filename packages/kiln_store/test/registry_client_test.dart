import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiln_store/kiln_store.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final fixtureRoot = Directory(
    p.join(Directory.current.path, 'test', 'fixtures', 'registry'),
  );
  final fixtureIndex = File(p.join(fixtureRoot.path, 'index.json'))
      .readAsStringSync();
  final validArchive = File(p.join(fixtureRoot.path, 'valid.tgz'))
      .readAsBytesSync();
  late Directory temp;
  late LocalCache cache;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('kiln_store_client_');
    cache = LocalCache(Directory(p.join(temp.path, 'cache')));
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  group('RegistryConfig', () {
    test('builds index URLs with and without trailing slashes', () {
      final config = RegistryConfig(url: 'https://example.com/registry');

      expect(
        config.indexUri.toString(),
        'https://example.com/registry/index.json',
      );
      expect(config.mirrorIndexUri, isNull);
      expect(
        config.resolve('archives/demo.tgz').toString(),
        'https://example.com/registry/archives/demo.tgz',
      );
      expect(
        config.resolve('/archives/demo.tgz').toString(),
        'https://example.com/registry/archives/demo.tgz',
      );

      final trailing = RegistryConfig(url: 'https://example.com/registry/');
      expect(
        trailing.indexUri.toString(),
        'https://example.com/registry/index.json',
      );
    });

    test('resolves the mirror index and paths', () {
      final config = RegistryConfig(
        url: 'https://example.com/registry',
        mirror: 'https://mirror.example.com/registry',
      );

      expect(
        config.mirrorIndexUri.toString(),
        'https://mirror.example.com/registry/index.json',
      );
      expect(
        config.resolve('valid.tgz', mirror: true).toString(),
        'https://mirror.example.com/registry/valid.tgz',
      );
    });

    test('expands the {ref} placeholder', () {
      final config = RegistryConfig(
        url: 'https://example.com/{ref}/registry',
        ref: 'v1.2.0',
      );

      expect(
        config.indexUri.toString(),
        'https://example.com/v1.2.0/registry/index.json',
      );
    });

    test('normalises local filesystem paths to file URIs', () {
      final config = RegistryConfig(url: temp.path);

      expect(config.indexUri.scheme, 'file');
      expect(
        p.equals(
          File.fromUri(config.indexUri).path,
          p.join(temp.path, 'index.json'),
        ),
        isTrue,
      );
      expect(config.resolve('archives/demo.tgz').scheme, 'file');
    });

    test('round-trips through maps and validates required fields', () {
      final config = RegistryConfig.fromMap(<String, Object?>{
        'url': 'https://example.com/registry',
        'mirror': 'https://mirror.example.com/registry',
        'ref': 'release',
      });

      expect(config.ref, 'release');
      expect(config.toJson(), <String, Object?>{
        'url': 'https://example.com/registry',
        'mirror': 'https://mirror.example.com/registry',
        'ref': 'release',
      });
      expect(
        () => RegistryConfig.fromMap(const <String, Object?>{}),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.invalid_config',
          ),
        ),
      );
      expect(
        () => RegistryConfig(url: 'ftp://example.com/registry'),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.invalid_config',
          ),
        ),
      );
    });
  });

  group('RegistryClient.fetchIndex', () {
    test('fetches over HTTP and caches the parsed index', () async {
      final requested = <Uri>[];
      final httpClient = MockClient((request) async {
        requested.add(request.url);
        return http.Response(fixtureIndex, 200);
      });
      final client = RegistryClient(
        config: RegistryConfig(url: 'https://example.com/registry'),
        httpClient: httpClient,
        cache: cache,
      );

      final index = await client.fetchIndex();

      expect(index.extensions, hasLength(2));
      expect(
        requested.single.toString(),
        'https://example.com/registry/index.json',
      );
      expect((await cache.readIndex())?.find('demo_ext'), isNotNull);
      client.close();
    });

    test('throws store.fetch_failed on non-200 responses', () async {
      final client = RegistryClient(
        config: RegistryConfig(url: 'https://example.com/registry'),
        httpClient: MockClient((request) async {
          return http.Response('missing', 404);
        }),
      );

      expect(
        () => client.fetchIndex(),
        throwsA(
          isA<KilnStoreException>()
              .having((error) => error.code, 'code', 'store.fetch_failed')
              .having((error) => error.details['status'], 'status', 404),
        ),
      );
      client.close();
    });

    test('falls back to the mirror when the primary fails', () async {
      final requested = <Uri>[];
      final client = RegistryClient(
        config: RegistryConfig(
          url: 'https://primary.example.com/registry',
          mirror: 'https://mirror.example.com/registry',
        ),
        httpClient: MockClient((request) async {
          requested.add(request.url);
          if (request.url.host == 'primary.example.com') {
            return http.Response('down', 503);
          }
          return http.Response(fixtureIndex, 200);
        }),
      );

      final index = await client.fetchIndex();

      expect(index.extensions, hasLength(2));
      expect(requested.map((uri) => uri.host), [
        'primary.example.com',
        'mirror.example.com',
      ]);
      client.close();
    });

    test('useMirror requests only the mirror', () async {
      final requested = <Uri>[];
      final client = RegistryClient(
        config: RegistryConfig(
          url: 'https://primary.example.com/registry',
          mirror: 'https://mirror.example.com/registry',
        ),
        httpClient: MockClient((request) async {
          requested.add(request.url);
          return http.Response(fixtureIndex, 200);
        }),
      );

      await client.fetchIndex(useMirror: true);

      expect(requested.single.host, 'mirror.example.com');
      client.close();
    });

    test('reads a registry from a local filesystem path', () async {
      final registry = Directory(p.join(temp.path, 'registry'))
        ..createSync(recursive: true);
      File(p.join(registry.path, 'index.json')).writeAsStringSync(fixtureIndex);
      final client = RegistryClient(config: RegistryConfig(url: registry.path));

      final index = await client.fetchIndex();

      expect(index.find('demo_ext')?.latest, '1.2.0');
      client.close();
    });

    test(
      'throws store.fetch_failed when a local registry is missing',
      () async {
        final client = RegistryClient(
          config: RegistryConfig(url: p.join(temp.path, 'missing')),
        );

        expect(
          () => client.fetchIndex(),
          throwsA(
            isA<KilnStoreException>().having(
              (error) => error.code,
              'code',
              'store.fetch_failed',
            ),
          ),
        );
        client.close();
      },
    );
  });

  group('RegistryClient.downloadArchive', () {
    RegistryVersion demoVersion(String version) {
      return RegistryIndex.parse(fixtureIndex)
          .find('demo_ext')!
          .findVersion(version)!;
    }

    test('downloads, verifies, and caches an archive', () async {
      final requested = <Uri>[];
      final config = RegistryConfig(url: 'https://example.com/registry');
      final client = RegistryClient(
        config: config,
        httpClient: MockClient((request) async {
          requested.add(request.url);
          return http.Response.bytes(validArchive, 200);
        }),
        cache: cache,
      );

      final bytes = await client.downloadArchive(
        'demo_ext',
        demoVersion('1.0.0'),
        indexUri: config.indexUri,
      );

      expect(bytes, validArchive);
      expect(
        requested.single.toString(),
        'https://example.com/registry/valid.tgz',
      );
      expect(await cache.readArchive('demo_ext', '1.0.0'), validArchive);
      client.close();
    });

    test('keeps absolute archive URLs untouched', () async {
      final requested = <Uri>[];
      final config = RegistryConfig(url: 'https://example.com/registry');
      final client = RegistryClient(
        config: config,
        httpClient: MockClient((request) async {
          requested.add(request.url);
          return http.Response.bytes(validArchive, 200);
        }),
      );
      final version = RegistryVersion(
        version: '1.2.0',
        url: 'https://cdn.example.com/kiln/demo_ext-1.2.0.tgz',
        sha256: sha256Hex(validArchive),
      );

      await client.downloadArchive(
        'demo_ext',
        version,
        indexUri: config.indexUri,
      );

      expect(
        requested.single.toString(),
        'https://cdn.example.com/kiln/demo_ext-1.2.0.tgz',
      );
      client.close();
    });

    test('rejects an archive whose checksum does not match', () async {
      final config = RegistryConfig(url: 'https://example.com/registry');
      final client = RegistryClient(
        config: config,
        httpClient: MockClient((request) async {
          return http.Response.bytes(validArchive, 200);
        }),
        cache: cache,
      );
      final version = RegistryVersion(
        version: '1.0.0',
        url: 'valid.tgz',
        sha256: 'f' * 64,
      );

      await expectLater(
        client.downloadArchive('demo_ext', version, indexUri: config.indexUri),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.checksum_mismatch',
          ),
        ),
      );
      expect(await cache.readArchive('demo_ext', '1.0.0'), isNull);
      client.close();
    });

    test(
      'throws store.fetch_failed when an archive cannot be downloaded',
      () async {
        final config = RegistryConfig(url: 'https://example.com/registry');
        final client = RegistryClient(
          config: config,
          httpClient: MockClient((request) async {
            return http.Response('gone', 500);
          }),
        );

        expect(
          () => client.downloadArchive(
            'demo_ext',
            demoVersion('1.1.0'),
            indexUri: config.indexUri,
          ),
          throwsA(
            isA<KilnStoreException>().having(
              (error) => error.code,
              'code',
              'store.fetch_failed',
            ),
          ),
        );
        client.close();
      },
    );
  });
}
