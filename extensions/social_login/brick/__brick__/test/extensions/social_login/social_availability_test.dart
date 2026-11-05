import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/social_login/social_availability.dart';

void main() {
  test('Google is available on mobile, macOS, and web', () {
    for (final platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    ]) {
      expect(
        SocialAvailability(platform: platform).supports(SocialProvider.google),
        isTrue,
      );
    }
    expect(
      const SocialAvailability(
        platform: TargetPlatform.linux,
        isWeb: true,
      ).supports(SocialProvider.google),
      isTrue,
    );
  });

  test('Apple follows the same platform list', () {
    expect(
      const SocialAvailability(platform: TargetPlatform.iOS)
          .supports(SocialProvider.apple),
      isTrue,
    );
    expect(
      const SocialAvailability(platform: TargetPlatform.windows)
          .supports(SocialProvider.apple),
      isFalse,
    );
  });
}
