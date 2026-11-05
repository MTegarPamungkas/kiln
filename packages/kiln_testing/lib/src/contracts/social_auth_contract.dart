import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef SocialAuthContractFactory = FutureOr<SocialAuth> Function();

/// Behavior every [SocialAuth] implementation must share.
void socialAuthContract({
  required SocialAuthContractFactory create,
  String description = 'SocialAuth',
  SocialProvider provider = SocialProvider.google,
}) {
  group('$description contract', () {
    test(
      'signIn returns a credential for the requested provider or null',
      () async {
        final auth = await create();

        final credential = await auth.signIn(provider);

        if (credential != null) {
          expect(credential.provider, provider);
          expect(credential.idToken, isNotEmpty);
        }
      },
    );

    test('signOut completes', () async {
      final auth = await create();

      await auth.signOut();
    });
  });
}
