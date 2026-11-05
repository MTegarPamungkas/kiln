import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/deep_link/app_link_builder.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_config.dart';
import 'package:{{app_name}}/extensions/deep_link/gate_deep_link.dart';

Gate _gate() {
  const config = DeepLinkConfig(
    scheme: 'kiln',
    allowedHosts: <String>['kiln.dev'],
  );
  final registry = GetItRegistry()
    ..registerSingleton<AppLinkBuilder>(AppLinkBuilder(config: config));
  return Gate(registry);
}

void main() {
  test('buildCustomLink returns the scheme link', () async {
    final result = await _gate().buildCustomLink('/profile/42');

    expect(result.valueOrNull.toString(), 'kiln://profile/42');
  });

  test('buildCustomLink reports an empty path as Err', () async {
    final result = await _gate().buildCustomLink('');

    expect(result.isErr, isTrue);
  });

  test('buildUniversalLink builds an https link', () async {
    final result = await _gate().buildUniversalLink('/app/home');

    expect(result.valueOrNull.toString(), 'https://kiln.dev/app/home');
  });
}
