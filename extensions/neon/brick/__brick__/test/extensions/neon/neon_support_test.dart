import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/neon/neon_config.dart';
import 'package:{{app_name}}/extensions/neon/neon_support.dart';

const NeonConfig _config = NeonConfig(
  dataApiUrl: 'https://example.aws.neon.tech/sql/rest',
  apiKey: 'token',
  schema: 'public',
);

void main() {
  test('reports supported without a probe and stays offline', () async {
    final support = NeonSupport(config: _config);

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(info.details['host'], 'example.aws.neon.tech');
    expect(info.details['schema'], 'public');
  });

  test('runs the reachability probe when one is provided', () async {
    var calls = 0;
    final support = NeonSupport(config: _config, probe: () async => calls++);

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(calls, 1);
  });

  test('reports missing configuration as not configured', () async {
    final support = NeonSupport(
      config: const NeonConfig(dataApiUrl: 'not-a-url', apiKey: ''),
    );

    final info = await support.check();

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().code, FailureCode.configurationMissing);
  });

  test('maps a configuration failure from the probe', () async {
    final support = NeonSupport(
      config: _config,
      probe: () async => throw const Failure(
        code: FailureCode.configurationInvalid,
        message: 'Bad schema',
        kind: FailureKind.configuration,
      ),
    );

    final info = await support.check();

    expect(info.state, SupportState.notConfigured);
    expect(info.message, 'Bad schema');
  });

  test('maps a probe error to unavailable', () async {
    final support = NeonSupport(
      config: _config,
      probe: () async => throw StateError('network down'),
    );

    final info = await support.check();

    expect(info.state, SupportState.unavailable);
  });

  test('caches the result until cleared', () async {
    var calls = 0;
    final support = NeonSupport(config: _config, probe: () async => calls++);

    await support.check();
    await support.check();
    expect(calls, 1);

    support.clear();
    await support.check();
    expect(calls, 2);
  });
}
