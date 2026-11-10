import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_account.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_config.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_session_bridge.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_social_auth.dart';

import 'test_support.dart';

void main() {
  const config = AppwriteConfig(
    endpoint: 'https://appwrite.test/v1',
    projectId: 'proj',
    databaseId: 'db',
    bucketId: 'bucket',
  );

  AppwriteSocialAuth social(
    FakeAppwriteAccount account,
    AppwriteSessionBridge bridge,
  ) {
    return AppwriteSocialAuth(
      account: account,
      config: config,
      bridge: bridge,
      timeout: const Duration(milliseconds: 40),
      pollInterval: const Duration(milliseconds: 5),
    );
  }

  test(
    'signs in through the OAuth callback and publishes the session',
    () async {
      final account = FakeAppwriteAccount()
        ..oauthUser = const AppwriteAccountUser(
          id: 'gh-1',
          email: 'ana@kiln.dev',
          name: 'Ana',
        );
      final bridge = AppwriteSessionBridge();
      final credential = await social(
        account,
        bridge,
      ).signIn(SocialProvider.google);

      expect(account.lastOAuthProvider, SocialProvider.google);
      expect(account.lastOAuthSuccessUrl, 'appwrite-callback-proj://');
      expect(credential, isNotNull);
      expect(credential!.provider, SocialProvider.google);
      expect(credential.email, 'ana@kiln.dev');
      expect(credential.displayName, 'Ana');
      expect(credential.idToken, 'jwt-gh-1');
      expect(bridge.session?.userId, 'gh-1');
    },
  );

  test(
    'returns null when the user cancels and never writes a session',
    () async {
      final account = FakeAppwriteAccount();
      final bridge = AppwriteSessionBridge();

      final credential = await social(
        account,
        bridge,
      ).signIn(SocialProvider.apple);

      expect(credential, isNull);
      expect(bridge.session, isNull);
    },
  );

  test('sign-out clears the account and the bridged session', () async {
    final account = FakeAppwriteAccount()
      ..setCurrent(
        const AppwriteAccountUser(id: 'gh-1', email: 'ana@kiln.dev'),
      );
    final bridge = AppwriteSessionBridge()..establish(user: account.current!);

    await social(account, bridge).signOut();

    expect(account.current, isNull);
    expect(bridge.session, isNull);
  });

  test('maps an Appwrite failure to an authentication Failure', () async {
    final account = FakeAppwriteAccount()
      ..failure = AppwriteException(
        'User (role: guests) missing scope (account)',
        401,
        'general_unauthorized_scope',
      );

    expect(
      () => social(
        account,
        AppwriteSessionBridge(),
      ).signIn(SocialProvider.google),
      throwsA(
        isA<Failure>().having(
          (f) => f.kind,
          'kind',
          FailureKind.authentication,
        ),
      ),
    );
  });
}
