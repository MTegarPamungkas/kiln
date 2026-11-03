import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_config.dart';
import 'package:{{app_name}}/extensions/analytics/analytics_support.dart';

AnalyticsConfig _config({String apiKey = 'phc_test'}) {
  return AnalyticsConfig(apiKey: apiKey, host: 'https://us.i.posthog.com');
}

void main() {
  test('reports supported when setup succeeds', () async {
    var calls = 0;
    final support = AnalyticsSupport(
      config: _config(),
      flavor: AppFlavor.production,
      probe: () async => calls++,
    );

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(info.details['host'], 'https://us.i.posthog.com');
    expect(calls, 1);
  });

  test('reports an empty API key as not configured', () async {
    final support = AnalyticsSupport(
      config: _config(apiKey: ''),
      flavor: AppFlavor.production,
      probe: () async {},
    );

    final info = await support.check();

    expect(info.state, SupportState.notConfigured);
    expect(info.message, contains('API key is empty'));
  });

  test('reports a disabled flavor as not configured', () async {
    final support = AnalyticsSupport(
      config: AnalyticsConfig(
        apiKey: 'phc_test',
        host: 'https://us.i.posthog.com',
        enabledFlavors: <AppFlavor>{AppFlavor.development},
      ),
      flavor: AppFlavor.production,
      probe: () async {},
    );

    final info = await support.check();

    expect(info.state, SupportState.notConfigured);
  });

  test('reports an invalid host as not configured', () async {
    final support = AnalyticsSupport(
      config: AnalyticsConfig(apiKey: 'phc_test', host: 'posthog'),
      flavor: AppFlavor.production,
      probe: () async {},
    );

    expect((await support.check()).state, SupportState.notConfigured);
  });

  test('maps a missing plugin to unsupported platform', () async {
    final support = AnalyticsSupport(
      config: _config(),
      flavor: AppFlavor.production,
      probe: () async => throw MissingPluginException('no posthog'),
    );

    expect((await support.check()).state, SupportState.unsupportedPlatform);
  });

  test('maps setup errors to unavailable', () async {
    final support = AnalyticsSupport(
      config: _config(),
      flavor: AppFlavor.production,
      probe: () async => throw StateError('posthog failed'),
    );

    final info = await support.check();

    expect(info.state, SupportState.unavailable);
    expect(info.toFailure().code, FailureCode.unavailable);
  });

  test('caches until cleared', () async {
    var calls = 0;
    final support = AnalyticsSupport(
      config: _config(),
      flavor: AppFlavor.production,
      probe: () async => calls++,
    );

    await support.check();
    await support.check();
    expect(calls, 1);

    support.clear();
    await support.check();
    expect(calls, 2);
  });
}
