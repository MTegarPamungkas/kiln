import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/social_login/gate_social_login.dart';

import 'test_support.dart';

Gate _gate(FakeSocialLogin login) {
  final registry = GetItRegistry()..registerSingleton<SocialLogin>(login);
  return Gate(registry);
}

void main() {
  test('socialLoginSignIn returns the native credential', () async {
    final login = FakeSocialLogin(credential: sampleGoogleCredential);
    final gate = _gate(login);

    final result = await gate.socialLoginSignIn(SocialProvider.google);

    expect(result.valueOrNull?.idToken, 'google-id-token');
    expect(login.providers, <SocialProvider>[SocialProvider.google]);
  });

  test('socialLoginSignIn reports a failure as Err', () async {
    final login = FakeSocialLogin(
      failure: const Failure(
        code: FailureCode.authCancelled,
        message: 'cancelled',
        kind: FailureKind.cancelled,
      ),
    );
    final gate = _gate(login);

    final result = await gate.socialLoginSignIn(SocialProvider.apple);

    expect(result.failureOrNull?.code, FailureCode.authCancelled);
  });

  test('socialLoginSignOut delegates to the login service', () async {
    final login = FakeSocialLogin();
    final gate = _gate(login);

    await gate.socialLoginSignOut();

    expect(login.signOutCalls, 1);
  });
}
