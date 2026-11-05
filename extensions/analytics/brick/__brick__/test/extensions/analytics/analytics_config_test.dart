import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_config.dart';

void main() {
  group('AnalyticsConfig', () {
    test('an empty API key keeps analytics off', () {
      expect(AnalyticsConfig.defaults.host, '{{{host}}}');
      final config = AnalyticsConfig(apiKey: '');

      expect(config.apiKey, isEmpty);
      expect(config.host, '{{{host}}}');
      expect(config.flushInterval, const Duration(seconds: 30));
      expect(config.enabledFlavors, AnalyticsConfig.defaultEnabledFlavors);
      expect(config.noopWhenApiKeyEmpty, isTrue);
      expect(config.isNoop, isTrue);
      expect(config.isActiveFor(AppFlavor.production), isFalse);
    });

    test('reads a custom key, host, interval, and flavor set', () {
      final config = AnalyticsConfig(
        apiKey: 'phc_test',
        host: 'https://eu.i.posthog.com',
        flushInterval: Duration(seconds: 10),
        enabledFlavors: <AppFlavor>{AppFlavor.production},
      );

      expect(config.hasApiKey, isTrue);
      expect(config.isNoop, isFalse);
      expect(config.flushInterval, const Duration(seconds: 10));
      expect(config.isActiveFor(AppFlavor.production), isTrue);
      expect(config.isActiveFor(AppFlavor.development), isFalse);
      expect(config.isActiveFor(null), isTrue);
    });

    test('an empty flavor set disables sending', () {
      final config = AnalyticsConfig(
        apiKey: 'phc_test',
        enabledFlavors: <AppFlavor>{},
      );

      expect(config.isFlavorEnabled(AppFlavor.production), isFalse);
      expect(config.isActiveFor(null), isFalse);
    });

    test('copyWith keeps the other settings', () {
      final config = AnalyticsConfig(apiKey: 'phc_test');

      final copy = config.copyWith(host: 'https://eu.i.posthog.com');

      expect(copy.apiKey, 'phc_test');
      expect(copy.host, 'https://eu.i.posthog.com');
      expect(copy.flushInterval, config.flushInterval);
      expect(copy.enabledFlavors, config.enabledFlavors);
    });

    test('validate rejects a relative host', () {
      final config = AnalyticsConfig(apiKey: 'phc_test', host: 'posthog');

      expect(
        config.validate,
        throwsA(
          isA<Failure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.configurationInvalid,
          ),
        ),
      );
    });

    test('validate rejects a non-positive flush interval', () {
      final config = AnalyticsConfig(
        apiKey: 'phc_test',
        flushInterval: Duration.zero,
      );

      expect(
        config.validate,
        throwsA(
          isA<Failure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.configurationInvalid,
          ),
        ),
      );
    });

    test('validate requires a key when the noop fallback is disabled', () {
      final config = AnalyticsConfig(
        apiKey: '',
        noopWhenApiKeyEmpty: false,
      );

      expect(
        config.validate,
        throwsA(
          isA<Failure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.configurationMissing,
          ),
        ),
      );
    });

    test('toString never exposes the API key', () {
      final config = AnalyticsConfig(apiKey: 'phc_secret');

      expect(config.toString(), isNot(contains('phc_secret')));
    });
  });
}
