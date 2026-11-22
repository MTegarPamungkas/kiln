import 'package:kiln_core/kiln_core.dart';

import 'apple_credential_gateway.dart';
import 'google_credential_gateway.dart';
import 'nonce_generator.dart';
import 'social_availability.dart';
import 'social_credentials.dart';
import 'social_login.dart';
import 'social_login_config.dart';
import 'social_login_support.dart';
import 'social_sign_out_listener.dart';

/// Registers SocialLogin and its provider gateways.
final class SocialLoginModule extends KilnModule {
  const SocialLoginModule();

  @override
  String get id => 'social_login';

  @override
  Set<String> get platforms => const <String>{
    'android',
    'ios',
    'macos',
    'web',
  };

  @override
  Set<String> get provides => const <String>{'social_login'};

  @override
  Set<String> get requires => const <String>{'social_auth'};

  @override
  void register(Registry registry) {
    const config = SocialLoginConfig.defaults;
    final availability = SocialAvailability.current();
    final support = SocialLoginSupport(
      config: config,
      availability: availability,
    );
    final google = SdkGoogleCredentialGateway();
    const apple = SdkAppleCredentialGateway();
    final login = DefaultSocialLogin(
      credentials: SocialCredentials(
        google: google,
        apple: apple,
        config: config,
        nonceGenerator: NonceGenerator(),
      ),
      availability: availability,
      config: config,
    );

    registry
      ..registerSingleton<SocialLoginConfig>(config)
      ..registerSingleton<SocialAvailability>(availability)
      ..registerSingleton<SocialLoginSupport>(support)
      ..registerSingleton<GoogleCredentialGateway>(google)
      ..registerSingleton<AppleCredentialGateway>(apple)
      ..registerSingleton<SocialLogin>(login);

    final auth = registry.readOrNull<AuthRepository>();
    if (auth != null) {
      final listener = SocialSignOutListener(auth: auth, google: google);
      registry.registerSingleton<SocialSignOutListener>(listener);
      // Disposed through the lifecycle so a late ready() cannot leave the
      // sign-out listener attached after the application is gone.
      registry
          .readOrNull<LifecycleController>()
          ?.addDisposeCallback(listener.dispose);
    }
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<SocialLoginSupport>().overall;
  }

  @override
  Future<void> ready(Registry registry) async {
    await registry.readOrNull<SocialSignOutListener>()?.start();
  }
}
