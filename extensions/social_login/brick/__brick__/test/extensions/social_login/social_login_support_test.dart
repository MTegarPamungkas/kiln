import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/social_login/social_availability.dart';
import 'package:{{app_name}}/extensions/social_login/social_login_config.dart';
import 'package:{{app_name}}/extensions/social_login/social_login_support.dart';

const SocialLoginConfig _configured = SocialLoginConfig(
  googleServerClientId: 'server-id',
  googleIosClientId: 'ios-id',
  appleServiceId: 'service-id',
  appleRedirectUri: 'https://app.kiln.dev/callback',
);

SocialLoginSupport _support(
  TargetPlatform platform, {
  SocialLoginConfig config = _configured,
  bool isWeb = false,
}) {
  return SocialLoginSupport(
    config: config,
    availability: SocialAvailability(platform: platform, isWeb: isWeb),
  );
}

void main() {
  test('reports supported when the provider is configured', () {
    final support = _support(TargetPlatform.android);

    expect(support.forProvider(SocialProvider.google).isSupported, isTrue);
    expect(support.overall.isSupported, isTrue);
    expect(support.overall.details['supported_providers'], contains('google'));
  });

  test('reports unsupported platforms', () {
    final support = _support(TargetPlatform.windows);

    expect(
      support.forProvider(SocialProvider.google).state,
      SupportState.unsupportedPlatform,
    );
    expect(support.overall.state, SupportState.unsupportedPlatform);
    expect(
      support.forProvider(SocialProvider.google).toFailure().code,
      FailureCode.unsupportedPlatform,
    );
  });

  test('reports missing credentials as not configured', () {
    final support = _support(
      TargetPlatform.android,
      config: const SocialLoginConfig(),
    );

    expect(
      support.forProvider(SocialProvider.google).state,
      SupportState.notConfigured,
    );
    expect(support.overall.state, SupportState.notConfigured);
  });

  test('web support follows the platform list', () {
    final support = _support(TargetPlatform.linux, isWeb: true);

    expect(support.forProvider(SocialProvider.google).isSupported, isTrue);
  });
}
