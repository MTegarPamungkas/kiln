import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_client.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_config.dart';

import 'test_support.dart';

void main() {
  group('RemoteConfigClient', () {
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

    test('a gateway failure throws a Failure and keeps the active snapshot',
        () async {
      final gateway = FakeRemoteConfigGateway();
      final client = RemoteConfigClient(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config.json'),
        gateway: gateway,
      );
      gateway.remoteValues = <String, Object?>{'v': 2};
      await client.fetchAndActivate();
      gateway.failure = StateError('down');

      await expectLater(client.fetch(), throwsA(isA<Failure>()));

      expect(client.getInt('v'), 2);
      await client.close();
    });
  });
}
