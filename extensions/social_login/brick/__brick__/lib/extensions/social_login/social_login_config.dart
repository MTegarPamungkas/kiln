import 'package:flutter/foundation.dart';
import 'package:kiln_core/kiln_core.dart';

import 'social_availability.dart';

/// Social login settings from the install prompts.
final class SocialLoginConfig {
  const SocialLoginConfig({
    this.googleServerClientId = '',
    this.googleIosClientId = '',
    this.appleServiceId = '',
    this.appleRedirectUri = '',
    this.enabledProviders = const <SocialProvider>{
      SocialProvider.google,
      SocialProvider.apple,
    },
  });

  static const defaults = SocialLoginConfig(
    googleServerClientId: '{{{google_server_client_id}}}',
    googleIosClientId: '{{{google_ios_client_id}}}',
    appleServiceId: '{{{apple_service_id}}}',
    appleRedirectUri: '{{{apple_redirect_uri}}}',
  );

  final String googleServerClientId;
  final String googleIosClientId;
  final String appleServiceId;
  final String appleRedirectUri;
  final Set<SocialProvider> enabledProviders;

  bool isEnabled(SocialProvider provider) =>
      enabledProviders.contains(provider);

  /// Whether the provider is enabled, supported, and configured.
  bool isReady(SocialProvider provider, SocialAvailability availability) {
    if (!isEnabled(provider) || !availability.supports(provider)) {
      return false;
    }
    final nativeApple =
        !availability.isWeb &&
        (availability.platform == TargetPlatform.iOS ||
            availability.platform == TargetPlatform.macOS);
    final googleNeedsServerId =
        availability.isWeb || availability.platform == TargetPlatform.android;
    return switch (provider) {
      SocialProvider.google =>
        googleNeedsServerId
            ? googleServerClientId.isNotEmpty
            : googleIosClientId.isNotEmpty || googleServerClientId.isNotEmpty,
      SocialProvider.apple =>
        nativeApple ||
            (appleServiceId.isNotEmpty && appleRedirectUri.isNotEmpty),
    };
  }
}
