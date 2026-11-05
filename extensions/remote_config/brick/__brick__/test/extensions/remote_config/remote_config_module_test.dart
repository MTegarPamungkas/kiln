import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_client.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_config.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_gateway.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_module.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_support.dart';

import 'test_support.dart';

void main() {
  group('RemoteConfigModule', () {
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
  });
}
