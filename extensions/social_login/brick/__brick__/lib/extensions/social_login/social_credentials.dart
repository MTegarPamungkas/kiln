import 'package:kiln_core/kiln_core.dart';

import 'apple_credential_gateway.dart';
import 'google_credential_gateway.dart';
import 'nonce_generator.dart';
import 'social_login_config.dart';

/// Obtains provider credentials through the SDK gateways.
final class SocialCredentials {
  const SocialCredentials({
    required this.google,
    required this.apple,
    required this.config,
    required this.nonceGenerator,
  });

  final GoogleCredentialGateway google;
  final AppleCredentialGateway apple;
  final SocialLoginConfig config;
  final NonceGenerator nonceGenerator;

  Future<SocialCredential?> obtain(SocialProvider provider) {
    return switch (provider) {
      SocialProvider.google => google.signIn(
        clientId: config.googleIosClientId.isEmpty
            ? null
            : config.googleIosClientId,
        serverClientId: config.googleServerClientId.isEmpty
            ? null
            : config.googleServerClientId,
      ),
      SocialProvider.apple => _apple(),
    };
  }

  Future<void> signOut() => google.signOut();

  Future<SocialCredential?> _apple() {
    final nonce = nonceGenerator.generate();
    return apple.signIn(
      nonce: nonce,
      nonceSha256: nonceGenerator.sha256(nonce),
      serviceId: config.appleServiceId.isEmpty ? null : config.appleServiceId,
      redirectUri: config.appleRedirectUri.isEmpty
          ? null
          : config.appleRedirectUri,
    );
  }
}
