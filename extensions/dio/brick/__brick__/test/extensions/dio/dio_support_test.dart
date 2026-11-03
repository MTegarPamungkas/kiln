import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/dio/dio_config.dart';
import 'package:{{app_name}}/extensions/dio/dio_support.dart';

void main() {
  test('reports supported for a valid HTTP config', () {
    const config = DioConfig(
      baseUrl: 'https://api.example.com/v1',
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 20),
    );

    final info = const DioSupport(config: config).info;

    expect(info.isSupported, isTrue);
    expect(info.details['host'], 'api.example.com');
    expect(info.details['api_key'], isFalse);
  });

  test('reports a missing base URL as not configured', () {
    const config = DioConfig(baseUrl: '');

    final info = const DioSupport(config: config).info;

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().code, FailureCode.configurationMissing);
  });

  test('reports a relative base URL as not configured', () {
    const config = DioConfig(baseUrl: '/api');

    final info = const DioSupport(config: config).info;

    expect(info.state, SupportState.notConfigured);
    expect(info.toFailure().code, FailureCode.configurationMissing);
  });

  test('reports invalid timeouts', () {
    const config = DioConfig(
      baseUrl: 'https://api.example.com',
      connectTimeout: Duration.zero,
    );

    expect(
      const DioSupport(config: config).info.toFailure().code,
      FailureCode.configurationMissing,
    );
  });
}
