import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_cache.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_client.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_config.dart';

import 'test_support.dart';

void main() {
  group('RemoteConfigClient', () {
    test(
      'a superseded fetchAndActivate cannot clear the active snapshot',
      () async {
        final gateway = FakeRemoteConfigGateway()..remoteValues = {'v': 1};
        final client = RemoteConfigClient(
          config: RemoteConfigConfig(
            endpoint: 'https://flags.test/config.json',
          ),
          gateway: gateway,
        );
        await client.fetchAndActivate();
        gateway.remoteValues = {'v': 9};
        await client.fetch(); // Staged values must remain inactive.
        gateway.loadGate = Completer<void>();
        final first = client.fetchAndActivate();
        await Future<void>.delayed(Duration.zero);
        final newer = client.fetch();
        gateway.remoteValues = {'v': 2};
        gateway.loadGate!.complete();
        await Future.wait([first, newer]);
        expect(client.getInt('v'), 1);
        client.activate();
        expect(client.getInt('v'), 2);
        await client.close();
      },
    );

    test('close fences in-flight and queued fetches and closes once', () async {
      final gateway = FakeRemoteConfigGateway()..loadGate = Completer<void>();
      final client = RemoteConfigClient(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config.json'),
        gateway: gateway,
      );
      client.setDefaults({'v': 1});
      final inFlight = client.fetchAndActivate();
      await Future<void>.delayed(Duration.zero);
      final queued = client.fetchAndActivate();
      await Future.wait([client.close(), client.close()]);
      gateway.remoteValues = {'v': 2};
      gateway.loadGate!.complete();
      await Future.wait([inFlight, queued]);
      expect(client.getInt('v'), 1);
      expect(gateway.loadCalls, 1);
      expect(gateway.closeCalls, 1);
      expect(client.activate, throwsStateError);
      expect(client.fetch, throwsStateError);
      expect(() => client.setDefaults({'v': 3}), throwsStateError);
    });

    test('fetch passes the endpoint and timeout to the gateway', () async {
      final gateway = FakeRemoteConfigGateway();
      final config = RemoteConfigConfig(
        endpoint: 'https://flags.test/config.json',
        requestTimeout: const Duration(seconds: 5),
      );
      final client = RemoteConfigClient(config: config, gateway: gateway);

      await client.fetch();

      expect(gateway.loadCalls, 1);
      expect(gateway.lastUrl, 'https://flags.test/config.json');
      expect(gateway.lastTimeout, const Duration(seconds: 5));
      await client.close();
    });

    test('an empty endpoint never touches the gateway', () async {
      final gateway = FakeRemoteConfigGateway();
      final client = RemoteConfigClient(
        config: RemoteConfigConfig(endpoint: ''),
        gateway: gateway,
      );

      await client.fetchAndActivate();

      expect(gateway.loadCalls, 0);
      expect(client.getBool('on'), isFalse);
      await client.close();
    });

    test(
      'a gateway failure throws a Failure and keeps the active snapshot',
      () async {
        final gateway = FakeRemoteConfigGateway();
        final client = RemoteConfigClient(
          config: RemoteConfigConfig(
            endpoint: 'https://flags.test/config.json',
          ),
          gateway: gateway,
        );
        gateway.remoteValues = <String, Object?>{'v': 2};
        await client.fetchAndActivate();
        gateway.failure = StateError('down');

        await expectLater(client.fetch(), throwsA(isA<Failure>()));

        expect(client.getInt('v'), 2);
        await client.close();
      },
    );

    test('persists a successful fetch for the next start', () async {
      final gateway = FakeRemoteConfigGateway()..remoteValues = {'v': 4};
      final cache = FakeRemoteConfigCache();
      final client = RemoteConfigClient(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config.json'),
        gateway: gateway,
        cache: cache,
      );

      await client.fetchAndActivate();

      expect(cache.saves, 1);
      expect(cache.snapshot!.values, <String, Object?>{'v': 4});
      await client.close();
    });

    test('a failing cache write does not fail the fetch', () async {
      final gateway = FakeRemoteConfigGateway()..remoteValues = {'v': 5};
      final cache = FakeRemoteConfigCache(failSave: true);
      final client = RemoteConfigClient(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config.json'),
        gateway: gateway,
        cache: cache,
      );

      await client.fetchAndActivate();

      expect(client.getInt('v'), 5);
      expect(client.isUsingCachedValues, isFalse);
      await client.close();
    });

    test(
      'activateCached serves a fresh snapshot and marks its source',
      () async {
        final gateway = FakeRemoteConfigGateway();
        final cache = FakeRemoteConfigCache(
          snapshot: RemoteConfigSnapshot(
            values: <String, Object?>{'v': 8},
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
        final client = RemoteConfigClient(
          config: RemoteConfigConfig(
            endpoint: 'https://flags.test/config.json',
          ),
          gateway: gateway,
          cache: cache,
        );

        expect(await client.activateCached(), isTrue);

        expect(client.getInt('v'), 8);
        expect(client.isUsingCachedValues, isTrue);
        // A network activation replaces the cached source.
        gateway.remoteValues = {'v': 9};
        await client.fetchAndActivate();
        expect(client.getInt('v'), 9);
        expect(client.isUsingCachedValues, isFalse);
        await client.close();
      },
    );

    test('activateCached ignores a snapshot older than the TTL', () async {
      final gateway = FakeRemoteConfigGateway();
      final cache = FakeRemoteConfigCache(
        snapshot: RemoteConfigSnapshot(
          values: <String, Object?>{'v': 8},
          fetchedAt: DateTime.now().toUtc().subtract(const Duration(hours: 48)),
        ),
      );
      final client = RemoteConfigClient(
        config: RemoteConfigConfig(
          endpoint: 'https://flags.test/config.json',
          cacheTtl: const Duration(hours: 24),
        ),
        gateway: gateway,
        cache: cache,
      );

      expect(await client.activateCached(), isFalse);
      expect(client.getInt('v', defaultValue: 0), 0);
      await client.close();
    });

    test(
      'activateCached is a no-op without a cache or with the TTL off',
      () async {
        final gateway = FakeRemoteConfigGateway();
        final noCache = RemoteConfigClient(
          config: RemoteConfigConfig(
            endpoint: 'https://flags.test/config.json',
          ),
          gateway: gateway,
        );
        expect(await noCache.activateCached(), isFalse);
        await noCache.close();

        final cache = FakeRemoteConfigCache(
          snapshot: RemoteConfigSnapshot(
            values: const <String, Object?>{'v': 1},
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
        final ttlOff = RemoteConfigClient(
          config: RemoteConfigConfig(
            endpoint: 'https://flags.test/config.json',
            cacheTtl: Duration.zero,
          ),
          gateway: gateway,
          cache: cache,
        );
        expect(await ttlOff.activateCached(), isFalse);
        await ttlOff.close();
      },
    );

    test('records the last fetch failure', () async {
      final gateway = FakeRemoteConfigGateway()
        ..failure = StateError('unreachable');
      final client = RemoteConfigClient(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config.json'),
        gateway: gateway,
      );

      await expectLater(client.fetch(), throwsA(isA<Failure>()));

      expect(client.lastFetchFailure, isA<Failure>());
      await client.close();
    });
  });
}
