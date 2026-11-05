import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/remote_config/remote_config_config.dart';

void main() {
  group('RemoteConfigConfig', () {
    test('an empty endpoint makes the source a noop', () {
      final config = RemoteConfigConfig(endpoint: '');

      expect(config.isNoop, isTrue);
      expect(config.isActiveFor(AppFlavor.production), isFalse);
    });

    test('an endpoint fetches for an enabled flavor', () {
      final config = RemoteConfigConfig(endpoint: 'https://flags.test/config');

      expect(config.isNoop, isFalse);
      expect(config.isActiveFor(AppFlavor.production), isTrue);
    });

    test('a flavor outside the enabled set does not fetch', () {
      final config = RemoteConfigConfig(
        endpoint: 'https://flags.test/config',
        enabledFlavors: <AppFlavor>{AppFlavor.staging},
      );

      expect(config.isActiveFor(AppFlavor.production), isFalse);
    });

    test('validate rejects a non-absolute endpoint', () {
      expect(
        () => RemoteConfigConfig(endpoint: 'not-a-url').validate(),
        throwsA(isA<Failure>()),
      );
    });

    test('validate rejects a zero fetch interval', () {
      expect(
        () => RemoteConfigConfig(
          endpoint: 'https://flags.test/config',
          fetchInterval: Duration.zero,
        ).validate(),
        throwsA(isA<Failure>()),
      );
    });

    test('validate requires an endpoint when the noop is off', () {
      expect(
        () => RemoteConfigConfig(
          endpoint: '',
          noopWhenEndpointEmpty: false,
        ).validate(),
        throwsA(isA<Failure>()),
      );
    });
  });
}
