import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/social_login/apple_credential_gateway.dart';
import 'package:{{app_name}}/extensions/social_login/google_credential_gateway.dart';
import 'package:{{app_name}}/extensions/social_login/social_availability.dart';
import 'package:{{app_name}}/extensions/social_login/social_login.dart';
import 'package:{{app_name}}/extensions/social_login/social_login_config.dart';
import 'package:{{app_name}}/extensions/social_login/social_login_module.dart';
import 'package:{{app_name}}/extensions/social_login/social_sign_out_listener.dart';

void main() {
  test('module registers SocialLogin and its gateways', () {
    final registry = GetItRegistry();

    const SocialLoginModule().register(registry);

    expect(registry.read<SocialLogin>(), isA<DefaultSocialLogin>());
    expect(registry.read<SocialLoginConfig>(), isA<SocialLoginConfig>());
    expect(registry.read<SocialAvailability>(), isA<SocialAvailability>());
    expect(
      registry.read<GoogleCredentialGateway>(),
      isA<GoogleCredentialGateway>(),
    );
    expect(
      registry.read<AppleCredentialGateway>(),
      isA<AppleCredentialGateway>(),
    );
  });

  test('module wires the sign-out listener when auth exists', () async {
    final auth = FakeAuthRepository();
    final registry = GetItRegistry()..registerSingleton<AuthRepository>(auth);

    const SocialLoginModule().register(registry);

    final listener = registry.read<SocialSignOutListener>();
    await listener.start();
    await auth.signIn(email: 'user@kiln.dev', password: 'password123');
    await auth.signOut();

    expect(
      registry.read<GoogleCredentialGateway>(),
      isA<GoogleCredentialGateway>(),
    );
    await listener.dispose();
    await auth.dispose();
  });
}
