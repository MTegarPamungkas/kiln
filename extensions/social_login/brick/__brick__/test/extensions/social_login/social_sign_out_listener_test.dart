import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:{{app_name}}/extensions/social_login/social_sign_out_listener.dart';

import 'test_support.dart';

void main() {
  test('signs out of Google when the auth session ends', () async {
    final auth = FakeAuthRepository();
    final google = FakeGoogleCredentialGateway();
    final listener = SocialSignOutListener(auth: auth, google: google);

    await listener.start();
    await auth.signIn(email: 'user@kiln.dev', password: 'password123');
    await auth.signOut();

    expect(google.signOutCalls, 1);

    await listener.dispose();
    await auth.dispose();
  });
}
