import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_cache.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_client.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_config.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_gateway.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_module.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_support.dart';

import 'test_support.dart';

void main() {
  group('RemoteConfigModule', () {
    test(
      'bootstrap reuses the support probe snapshot without another fetch',
      () async {
        final gateway = FakeRemoteConfigGateway()..remoteValues = {'v': 7};
        final registry = await KilnBootstrap.run(
          modules: [
            RemoteConfigModule(
              config: RemoteConfigConfig(endpoint: 'https://flags.test/config'),
              gatewayFactory: () => gateway,
            ),
          ],
        );
        expect(gateway.loadCalls, 1);
        expect(registry.read<RemoteConfig>().getInt('v'), 7);
        await registry.read<Lifecycle>().dispose();
      },
    );
    test('registers RemoteConfig and its parts', () async {
      final registry = GetItRegistry();
      final gateway = FakeRemoteConfigGateway();
      final module = RemoteConfigModule(gatewayFactory: () => gateway);

      module.register(registry);

      expect(registry.read<RemoteConfig>(), isA<RemoteConfigClient>());
      expect(registry.read<RemoteConfigConfig>(), isA<RemoteConfigConfig>());
      expect(registry.read<RemoteConfigSupport>(), isA<RemoteConfigSupport>());
      expect(registry.read<RemoteConfigGateway>(), same(gateway));

      await module.dispose();
    });

    test('loads values during ready when active', () async {
      final registry = GetItRegistry();
      final gateway = FakeRemoteConfigGateway()
        ..remoteValues = <String, Object?>{'v': 1, 'on': true};
      final module = RemoteConfigModule(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config'),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      expect(gateway.loadCalls, 1);
      final config = registry.read<RemoteConfig>();
      expect(config.getInt('v'), 1);
      expect(config.getBool('on'), isTrue);

      await module.dispose();
    });

    test('skips the network entirely when the endpoint is empty', () async {
      final registry = GetItRegistry();
      final gateway = FakeRemoteConfigGateway();
      final module = RemoteConfigModule(
        config: RemoteConfigConfig(endpoint: ''),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      expect(gateway.loadCalls, 0);

      await module.dispose();
    });

    test('refreshes once when the app resumes after the fetch interval', () async {
      final clock = FixedClock.at(2026, 11, 22);
      final lifecycle = LifecycleController();
      final gateway = FakeRemoteConfigGateway()
        ..remoteValues = <String, Object?>{'v': 1};
      final registry = GetItRegistry()
        ..registerSingleton<Clock>(clock)
        ..registerSingleton<Lifecycle>(lifecycle);
      final module = RemoteConfigModule(
        config: RemoteConfigConfig(
          endpoint: 'https://flags.test/config',
          fetchInterval: const Duration(minutes: 15),
        ),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);
      expect(gateway.loadCalls, 1);
      expect(registry.read<RemoteConfig>().getInt('v'), 1);

      clock.advance(const Duration(minutes: 5));
      gateway.remoteValues = <String, Object?>{'v': 2};
      await lifecycle.onResume();
      await Future<void>.delayed(Duration.zero);
      expect(gateway.loadCalls, 1, reason: 'too soon to refresh');

      await lifecycle.onPause();
      clock.advance(const Duration(minutes: 30));
      await lifecycle.onResume();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(gateway.loadCalls, 2);
      expect(registry.read<RemoteConfig>().getInt('v'), 2);

      await lifecycle.dispose();
      await module.dispose();
    });

    test('does not watch the lifecycle when resume refresh is off', () async {
      final clock = FixedClock.at(2026, 11, 22);
      final lifecycle = LifecycleController();
      final gateway = FakeRemoteConfigGateway()
        ..remoteValues = <String, Object?>{'v': 1};
      final registry = GetItRegistry()
        ..registerSingleton<Clock>(clock)
        ..registerSingleton<Lifecycle>(lifecycle);
      final module = RemoteConfigModule(
        config: RemoteConfigConfig(
          endpoint: 'https://flags.test/config',
          fetchInterval: const Duration(minutes: 1),
          refreshOnResume: false,
        ),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);
      clock.advance(const Duration(hours: 1));
      await lifecycle.onResume();
      await Future<void>.delayed(Duration.zero);
      expect(gateway.loadCalls, 1);

      await lifecycle.dispose();
      await module.dispose();
    });

    test('keeps starting when the initial fetch fails', () async {
      final registry = GetItRegistry();
      final gateway = FakeRemoteConfigGateway()
        ..failure = StateError('unreachable');
      final module = RemoteConfigModule(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config'),
        gatewayFactory: () => gateway,
      );

      module.register(registry);
      await module.ready(registry);

      expect(gateway.loadCalls, 1);
      expect(registry.read<RemoteConfig>().getBool('missing'), isFalse);

      await module.dispose();
    });

    test('serves a fresh snapshot when the endpoint is unreachable', () async {
      final storage = InMemoryStorage();
      await StorageRemoteConfigCache(storage: storage).save(
        RemoteConfigSnapshot(
          values: <String, Object?>{'v': 11},
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
      final registry = GetItRegistry()..registerSingleton<Storage>(storage);
      final gateway = FakeRemoteConfigGateway()
        ..failure = StateError('unreachable');
      final module = RemoteConfigModule(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config'),
        gatewayFactory: () => gateway,
      )..register(registry);

      final support = await module.support(registry);
      await module.ready(registry);

      expect(support.isSupported, isTrue);
      expect(gateway.loadCalls, 1);
      expect(registry.read<RemoteConfig>().getInt('v'), 11);
      expect(registry.read<RemoteConfigClient>().isUsingCachedValues, isTrue);
      await module.dispose();
    });

    test(
      'reports unavailable when unreachable and no snapshot is stored',
      () async {
        final storage = InMemoryStorage();
        final registry = GetItRegistry()..registerSingleton<Storage>(storage);
        final gateway = FakeRemoteConfigGateway()
          ..failure = StateError('unreachable');
        final module = RemoteConfigModule(
          config: RemoteConfigConfig(endpoint: 'https://flags.test/config'),
          gatewayFactory: () => gateway,
        )..register(registry);

        final support = await module.support(registry);

        expect(support.isSupported, isFalse);
        await module.dispose();
      },
    );

    test('ignores a snapshot older than the cache TTL', () async {
      final storage = InMemoryStorage();
      await StorageRemoteConfigCache(storage: storage).save(
        RemoteConfigSnapshot(
          values: <String, Object?>{'v': 11},
          fetchedAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
        ),
      );
      final registry = GetItRegistry()..registerSingleton<Storage>(storage);
      final gateway = FakeRemoteConfigGateway()
        ..failure = StateError('unreachable');
      final module = RemoteConfigModule(
        config: RemoteConfigConfig(
          endpoint: 'https://flags.test/config',
          cacheTtl: const Duration(hours: 24),
        ),
        gatewayFactory: () => gateway,
      )..register(registry);

      final support = await module.support(registry);

      expect(support.isSupported, isFalse);
      expect(registry.read<RemoteConfig>().getInt('v', defaultValue: 0), 0);
      await module.dispose();
    });

    test('persists a successful fetch for the next start', () async {
      final storage = InMemoryStorage();
      final registry = GetItRegistry()..registerSingleton<Storage>(storage);
      final gateway = FakeRemoteConfigGateway()
        ..remoteValues = <String, Object?>{'v': 12};
      final module = RemoteConfigModule(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config'),
        gatewayFactory: () => gateway,
      )..register(registry);

      await module.ready(registry);

      final stored = await StorageRemoteConfigCache(storage: storage).load();
      expect(stored, isNotNull);
      expect(stored!.values, <String, Object?>{'v': 12});
      expect(registry.read<RemoteConfig>().getInt('v'), 12);
      await module.dispose();
    });
  });
}
