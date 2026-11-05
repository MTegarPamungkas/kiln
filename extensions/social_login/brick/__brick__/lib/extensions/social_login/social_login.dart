import 'package:kiln_core/kiln_core.dart';

import 'social_availability.dart';
import 'social_credentials.dart';
import 'social_login_config.dart';
import 'social_login_failure_mapper.dart';
import 'social_login_support.dart';

/// [SocialLogin] backed by Google and Apple credential gateways.
final class DefaultSocialLogin implements SocialLogin {
  const DefaultSocialLogin({
    required this.credentials,
    required this.availability,
    required this.config,
  });

  final SocialCredentials credentials;
  final SocialAvailability availability;
  final SocialLoginConfig config;

  @override
  Future<SocialCredential?> signIn(SocialProvider provider) async {
    final support = SocialLoginSupport(
      config: config,
      availability: availability,
    ).forProvider(provider);
    if (support.isPlatformUnsupported) {
      throw support.toFailure();
    }
    if (!config.isReady(provider, availability)) {
      throw Failure(
        code: FailureCode.authProviderDisabled,
        message: 'Sign-in with ${_label(provider)} is unavailable.',
        kind: FailureKind.authentication,
      );
    }
    try {
      return await credentials.obtain(provider);
    } on Object catch (error, stackTrace) {
      throw mapSocialLoginError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> signOut() => credentials.signOut();

  String _label(SocialProvider provider) {
    return switch (provider) {
      SocialProvider.google => 'Google',
      SocialProvider.apple => 'Apple',
    };
  }
}
