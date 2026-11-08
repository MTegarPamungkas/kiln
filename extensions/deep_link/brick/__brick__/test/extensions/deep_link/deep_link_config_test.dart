import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/deep_link/deep_link_config.dart';

void main() {
  test('defaults carry the rendered prompts', () {
    const config = DeepLinkConfig.defaults;

    expect(config.scheme, '{{scheme}}');
    expect(config.allowedHosts, <String>['kiln.dev']);
    expect(config.pathPrefixes, isEmpty);
    expect(config.schemeName, '{{scheme}}');
    expect(config.allowsUniversalLinks, isTrue);
    expect(config.restrictsPaths, isFalse);
  });

  test('normalization options have safe defaults', () {
    const config = DeepLinkConfig.defaults;

    expect(config.stripTrackingParameters, isTrue);
    expect(config.dropFragment, isTrue);
    expect(config.deduplicationWindow, const Duration(seconds: 2));
    expect(config.trackingParameters, contains('utm_source'));
    expect(config.trackingParameters, contains('fbclid'));
  });

  test('a custom config keeps typed values and normalizes the scheme', () {
    const config = DeepLinkConfig(
      scheme: 'Kiln://',
      allowedHosts: <String>['Example.com'],
      pathPrefixes: <String>['app'],
      stripTrackingParameters: false,
    );

    expect(config.schemeName, 'kiln');
    expect(config.allowedHosts, <String>['Example.com']);
    expect(config.pathPrefixes, <String>['app']);
    expect(config.restrictsPaths, isTrue);
    expect(config.stripTrackingParameters, isFalse);
  });

  test('a config without hosts rejects universal links only', () {
    const config = DeepLinkConfig(scheme: 'kiln');

    expect(config.allowsUniversalLinks, isFalse);
    expect(config.schemeName, 'kiln');
  });
}
