import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/social_login/social_login_config.dart';

import 'test_support.dart';

void main() {
  test('defaults carry the rendered client ids', () {
    const config = SocialLoginConfig.defaults;

    expect(config.googleServerClientId, isEmpty);
    expect(config.googleIosClientId, isEmpty);
    expect(config.appleServiceId, isEmpty);
    expect(config.enabledProviders, hasLength(2));
  });

  test('requires Google ids before the provider is ready', () {
    const empty = SocialLoginConfig();
    const configured = SocialLoginConfig(googleServerClientId: 'server');

    expect(
      empty.isReady(SocialProvider.google, androidAvailability()),
      isFalse,
    );
    expect(
      configured.isReady(SocialProvider.google, androidAvailability()),
      isTrue,
    );
  });

  test('uses native Apple without a service id', () {
    const config = SocialLoginConfig();

    expect(config.isReady(SocialProvider.apple, iosAvailability()), isTrue);
    expect(
      config.isReady(SocialProvider.apple, androidAvailability()),
      isFalse,
    );
  });

  test('honours disabled providers', () {
    const config = SocialLoginConfig(
      googleServerClientId: 'server',
      enabledProviders: <SocialProvider>{SocialProvider.apple},
    );

    expect(
      config.isReady(SocialProvider.google, androidAvailability()),
      isFalse,
    );
  });
}
