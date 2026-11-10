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
  late RegistryConfig config;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('kiln_store_offline_');
    config = RegistryConfig(url: 'https://example.com/registry');
    cache = LocalCache(Directory(p.join(temp.path, 'cache')), registry: config);
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  RegistryClient clientThatMustNotBeUsed() {
    return RegistryClient(
      config: config,
      httpClient: MockClient((request) async {
        fail('network used for ${request.url}');
      }),
      cache: cache,
    );
  }

  group('OfflineMode.index', () {
    test(
      'offline returns the cached index without touching the network',
      () async {
        cache.writeIndex(RegistryIndex.parse(fixtureIndex));
        final mode = OfflineMode(
          client: clientThatMustNotBeUsed(),
          cache: cache,
          offline: true,
        );

        final index = await mode.index();

        expect(index.find('demo_ext')?.latest, '1.2.0');
      },
    );

    test(
      'offline without a cached index throws store.offline_missing',
      () async {
        final mode = OfflineMode(
          client: clientThatMustNotBeUsed(),
          cache: cache,
          offline: true,
        );

        expect(
          () => mode.index(),
          throwsA(
            isA<KilnStoreException>().having(
              (error) => error.code,
              'code',
              'store.offline_missing',
            ),
          ),
        );
      },
    );

    test('online fetches and writes the cache', () async {
      final client = RegistryClient(
        config: config,
        httpClient: MockClient((request) async {
          return http.Response(fixtureIndex, 200);
        }),
        cache: cache,
      );
      final mode = OfflineMode(client: client, cache: cache);

      final index = await mode.index();

      expect(index.extensions, hasLength(2));
      expect((await cache.readIndex())?.find('http_retry'), isNotNull);
      client.close();
    });

    test('online falls back to the cache when the network fails', () async {
      cache.writeIndex(RegistryIndex.parse(fixtureIndex));
      final client = RegistryClient(
        config: config,
        httpClient: MockClient((request) async {
          throw const SocketException('offline');
        }),
        cache: cache,
      );
      final mode = OfflineMode(client: client, cache: cache);

      final index = await mode.index();

      expect(index.find('demo_ext'), isNotNull);
      client.close();
    });

    test('online rethrows fetch failures when the cache is empty', () async {
      final client = RegistryClient(
        config: config,
        httpClient: MockClient((request) async {
          return http.Response('unavailable', 503);
        }),
      );
      final mode = OfflineMode(client: client, cache: cache);

      expect(
        () => mode.index(),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.fetch_failed',
          ),
        ),
      );
      client.close();
    });
  });

  group('OfflineMode.archive', () {
    final selected = RegistryIndex.parse(fixtureIndex).find('demo_ext')!.findVersion('1.0.0')!;
    Matcher errorCode(String code) => throwsA(isA<KilnStoreException>().having((e) => e.code, 'code', code));

    test('verified offline hit requires matching cached metadata', () async {
      cache.writeIndex(RegistryIndex.parse(fixtureIndex));
      cache.writeArchive('demo_ext', '1.0.0', validArchive);
      final mode = OfflineMode(client: clientThatMustNotBeUsed(), cache: cache, offline: true);
      expect(await mode.archive('demo_ext', selected), validArchive);
      cache.archiveFile('demo_ext', '1.0.0').writeAsBytesSync([1, 2, 3]);
      await expectLater(mode.archive('demo_ext', selected), errorCode('store.checksum_mismatch'));
    });

    test('archive alone is not trusted offline metadata', () async {
      cache.writeArchive('demo_ext', '1.0.0', validArchive);
      final mode = OfflineMode(client: clientThatMustNotBeUsed(), cache: cache, offline: true);
      await expectLater(mode.archive('demo_ext', selected), errorCode('store.offline_missing'));
      cache.writeIndex(RegistryIndex.parse(fixtureIndex));
      final changed = RegistryVersion(version: selected.version, url: selected.url, sha256: 'a' * 64);
      await expectLater(mode.archive('demo_ext', changed), errorCode('store.offline_missing'));
    });

    test('offline refuses missing archive and unknown metadata', () async {
      cache.writeIndex(RegistryIndex.parse(fixtureIndex));
      final mode = OfflineMode(client: clientThatMustNotBeUsed(), cache: cache, offline: true);
      await expectLater(mode.archive('demo_ext', selected), errorCode('store.offline_missing'));
      await expectLater(mode.archive('missing', selected), errorCode('store.offline_missing'));
    });

    for (final corrupt in [false, true]) {
      test('online download (corrupt=$corrupt) pins selected URL and SHA without lookup', () async {
        if (corrupt) cache.writeArchive('demo_ext', '1.0.0', [9]);
        final requested = <Uri>[];
        final client = RegistryClient(config: config, cache: cache,
          httpClient: MockClient((request) async {
            requested.add(request.url);
            if (request.url.path.endsWith('index.json')) fail('Selected metadata must not be looked up again');
            return http.Response.bytes(validArchive, 200);
          }),
        );
        final mode = OfflineMode(client: client, cache: cache);
        expect(await mode.archive('demo_ext', selected), validArchive);
        expect(await cache.readArchive('demo_ext', '1.0.0'), validArchive);
        expect(requested.map((uri) => uri.path), ['/registry/valid.tgz']);
        client.close();
      });
    }

    test('online cache hit cannot substitute a different selected checksum', () async {
      cache.writeArchive('demo_ext', '1.0.0', validArchive);
      final changed = RegistryVersion(version: selected.version, url: selected.url, sha256: 'a' * 64);
      final client = RegistryClient(config: config, httpClient: MockClient((_) async => http.Response.bytes(validArchive, 200)));
      await expectLater(OfflineMode(client: client, cache: cache).archive('demo_ext', changed), errorCode('store.checksum_mismatch'));
      client.close();
    });
  });
}
