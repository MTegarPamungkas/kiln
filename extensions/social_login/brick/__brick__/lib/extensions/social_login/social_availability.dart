import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

/// Which social providers the running platform can show.
final class SocialAvailability {
  const SocialAvailability({required this.platform, this.isWeb = false});

  factory SocialAvailability.current() {
    return SocialAvailability(platform: defaultTargetPlatform, isWeb: kIsWeb);
  }

  final TargetPlatform platform;
  final bool isWeb;

  bool supports(SocialProvider provider) {
    return switch (provider) {
      SocialProvider.google =>
        isWeb ||
            platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS ||
            platform == TargetPlatform.macOS,
      SocialProvider.apple =>
        isWeb ||
            platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS ||
            platform == TargetPlatform.macOS,
    };
  }
}
