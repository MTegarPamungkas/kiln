import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/social_login/nonce_generator.dart';
import 'package:{{app_name}}/extensions/social_login/social_availability.dart';
import 'package:{{app_name}}/extensions/social_login/social_credentials.dart';
import 'package:{{app_name}}/extensions/social_login/social_login.dart';
import 'package:{{app_name}}/extensions/social_login/social_login_config.dart';

import 'test_support.dart';

const SocialLoginConfig _config = SocialLoginConfig(
  googleServerClientId: 'server-id',
  googleIosClientId: 'ios-id',
  appleServiceId: 'service-id',
  appleRedirectUri: 'https://app.kiln.dev/callback',
);

DefaultSocialLogin _login({
  FakeGoogleCredentialGateway? google,
  FakeAppleCredentialGateway? apple,
  SocialAvailability? availability,
  SocialLoginConfig config = _config,
}) {
  return DefaultSocialLogin(
    credentials: SocialCredentials(
      google: google ?? FakeGoogleCredentialGateway(),
      apple: apple ?? FakeAppleCredentialGateway(),
      config: config,
      nonceGenerator: NonceGenerator(),
    ),
    availability: availability ?? androidAvailability(),
    config: config,
  );
}

void main() {
  test('signs in with Google using the configured client ids', () async {
    final google = FakeGoogleCredentialGateway()
      ..credential = sampleGoogleCredential;
    final login = _login(google: google);

    final credential = await login.signIn(SocialProvider.google);

    expect(credential?.idToken, 'google-id-token');
    expect(google.serverClientId, 'server-id');
    expect(google.clientId, 'ios-id');
  });

  test('signs in with Apple using a hashed nonce', () async {
    final apple = FakeAppleCredentialGateway()
      ..credential = sampleAppleCredential;
    final login = _login(apple: apple);

    final credential = await login.signIn(SocialProvider.apple);

    expect(credential?.idToken, 'apple-id-token');
    expect(apple.nonce, isNotEmpty);
    expect(apple.nonceSha256, hasLength(64));
    expect(apple.serviceId, 'service-id');
    expect(apple.redirectUri, 'https://app.kiln.dev/callback');
  });

  test('rejects a provider that is not configured', () async {
    final login = _login(config: const SocialLoginConfig());

    await expectLater(
      login.signIn(SocialProvider.google),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authProviderDisabled,
        ),
      ),
    );
  });

  test('wraps SDK cancellations', () async {
    final google = FakeGoogleCredentialGateway()
      ..failure = StateError('The operation was canceled');
    final login = _login(google: google);

    await expectLater(
      login.signIn(SocialProvider.google),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authCancelled,
        ),
      ),
    );
  });

  test('signOut clears the Google session', () async {
    final google = FakeGoogleCredentialGateway();
    final login = _login(google: google);

    await login.signOut();

    expect(google.signOutCalls, 1);
  });
}
