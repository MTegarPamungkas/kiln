import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/rest_auth/rest_auth_config.dart';
import 'package:{{app_name}}/extensions/rest_auth/rest_auth_support.dart';

const RestAuthConfig _config = RestAuthConfig(
  baseUrl: 'https://api.example.com',
);

void main() {
  test('reports supported when config and storage are ready', () async {
    var probes = 0;
    final support = RestAuthSupport(
      config: _config,
      storageProbe: () async => probes++,
    );

    final info = await support.check();

    expect(info.isSupported, isTrue);
    expect(info.details['host'], 'api.example.com');
    expect(probes, 1);
  });

  test('reports a missing or invalid base URL as not configured', () async {
    final missing = RestAuthSupport(
      config: const RestAuthConfig(),
      storageProbe: () async {},
    );
    final invalid = RestAuthSupport(
      config: const RestAuthConfig(baseUrl: 'api'),
      storageProbe: () async {},
    );

    expect((await missing.check()).state, SupportState.notConfigured);
    expect((await invalid.check()).state, SupportState.notConfigured);
  });

  test('rejects an empty endpoint path', () async {
    final support = RestAuthSupport(
      config: const RestAuthConfig(
        baseUrl: 'https://api.example.com',
        loginPath: '',
      ),
      storageProbe: () async {},
    );

    expect((await support.check()).state, SupportState.notConfigured);
  });

  test(
    'maps a missing secure storage plugin to unsupported platform',
    () async {
      final support = RestAuthSupport(
        config: _config,
        storageProbe: () async => throw MissingPluginException('no keystore'),
      );

      expect((await support.check()).state, SupportState.unsupportedPlatform);
    },
  );

  test('maps storage errors to unavailable', () async {
    final support = RestAuthSupport(
      config: _config,
      storageProbe: () async => throw StateError('keystore failed'),
    );

    final info = await support.check();

    expect(info.state, SupportState.unavailable);
    expect(info.toFailure().code, FailureCode.unavailable);
  });

  test('caches until cleared', () async {
    var probes = 0;
    final support = RestAuthSupport(
      config: _config,
      storageProbe: () async => probes++,
    );

    await support.check();
    await support.check();
    expect(probes, 1);

    support.clear();
    await support.check();
    expect(probes, 2);
  });
}
