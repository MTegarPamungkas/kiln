import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_config.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_support.dart';

void main() {
  group('RemoteConfigSupport', () {
    test('is not configured when the endpoint is empty', () async {
      final support = RemoteConfigSupport(
        config: RemoteConfigConfig(endpoint: ''),
        flavor: null,
        probe: () async {},
      );

      final info = await support.check();

      expect(info.state, SupportState.notConfigured);
      expect(info.isSupported, isFalse);
    });

    test('is supported when active and reachable', () async {
      final support = RemoteConfigSupport(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config'),
        flavor: AppFlavor.production,
        probe: () async {},
      );

      final info = await support.check();

      expect(info.isSupported, isTrue);
    });

    test('is unavailable when the probe throws', () async {
      final support = RemoteConfigSupport(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config'),
        flavor: AppFlavor.production,
        probe: () async => throw StateError('unreachable'),
      );

      final info = await support.check();

      expect(info.state, SupportState.unavailable);
    });

    test('caches the probe result', () async {
      var calls = 0;
      final support = RemoteConfigSupport(
        config: RemoteConfigConfig(endpoint: 'https://flags.test/config'),
        flavor: AppFlavor.production,
        probe: () async {
          calls++;
        },
      );

      await support.check();
      await support.check();

      expect(calls, 1);
    });
  });
}
