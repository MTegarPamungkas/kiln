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
    cache = LocalCache(Directory(p.join(temp.path, 'cache')));
    config = RegistryConfig(url: 'https://example.com/registry');
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
    test('returns a cached archive without touching the network', () async {
      cache.writeArchive('demo_ext', '1.0.0', validArchive);
      final mode = OfflineMode(
        client: clientThatMustNotBeUsed(),
        cache: cache,
        offline: true,
      );

      expect(await mode.archive('demo_ext', '1.0.0'), validArchive);
    });

    test('downloads and caches an archive when missing', () async {
      final requested = <Uri>[];
      final client = RegistryClient(
        config: config,
        httpClient: MockClient((request) async {
          requested.add(request.url);
          if (request.url.path.endsWith('index.json')) {
            return http.Response(fixtureIndex, 200);
          }
          return http.Response.bytes(validArchive, 200);
        }),
        cache: cache,
      );
      final mode = OfflineMode(client: client, cache: cache);

      final bytes = await mode.archive('demo_ext', '1.0.0');

      expect(bytes, validArchive);
      expect(await cache.readArchive('demo_ext', '1.0.0'), validArchive);
      expect(
        requested.map((uri) => uri.path),
        containsAll(<String>['/registry/index.json', '/registry/valid.tgz']),
      );
      client.close();
    });

    test('offline refuses an archive missing from the cache', () async {
      cache.writeIndex(RegistryIndex.parse(fixtureIndex));
      final mode = OfflineMode(
        client: clientThatMustNotBeUsed(),
        cache: cache,
        offline: true,
      );

      expect(
        () => mode.archive('demo_ext', '1.0.0'),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.offline_missing',
          ),
        ),
      );
    });

    test('throws for unknown extensions and versions', () async {
      cache.writeIndex(RegistryIndex.parse(fixtureIndex));
      final mode = OfflineMode(
        client: clientThatMustNotBeUsed(),
        cache: cache,
        offline: true,
      );

      expect(
        () => mode.archive('missing', '1.0.0'),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.extension_not_found',
          ),
        ),
      );
      expect(
        () => mode.archive('demo_ext', '9.9.9'),
        throwsA(
          isA<KilnStoreException>().having(
            (error) => error.code,
            'code',
            'store.version_not_found',
          ),
        ),
      );
    });
  });
}
