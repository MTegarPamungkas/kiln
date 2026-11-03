import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/social_login/nonce_generator.dart';
import 'package:{{app_name}}/extensions/social_login/social_credentials.dart';
import 'package:{{app_name}}/extensions/social_login/social_login.dart';
import 'package:{{app_name}}/extensions/social_login/social_login_config.dart';

import 'test_support.dart';

void main() {
  socialAuthContract(
    description: 'DefaultSocialLogin',
    create: () {
      final google = FakeGoogleCredentialGateway()
        ..credential = sampleGoogleCredential;
      final apple = FakeAppleCredentialGateway()
        ..credential = sampleAppleCredential;
      const config = SocialLoginConfig(
        googleServerClientId: 'server',
        googleIosClientId: 'ios',
      );
      return DefaultSocialLogin(
        credentials: SocialCredentials(
          google: google,
          apple: apple,
          config: config,
          nonceGenerator: NonceGenerator(),
        ),
        availability: androidAvailability(),
        config: config,
      );
    },
  );
}
