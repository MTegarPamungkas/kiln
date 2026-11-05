import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_account.dart';
import 'package:with_appwrite/extensions/appwrite/appwrite_account_management.dart';

import 'test_support.dart';

void main() {
  test(
    'reset password and verification use the configured redirects',
    () async {
      final account = FakeAppwriteAccount();
      final management = AppwriteAccountManagement(account: account);

      await management.sendPasswordResetEmail('user@kiln.dev');
      await management.sendEmailVerification();

      expect(
        account.calls,
        contains(
          'reset:user@kiln.dev:'
          '${AppwriteAccountManagement.defaultRecoveryRedirectUrl}',
        ),
      );
      expect(
        account.calls,
        contains(
          'verify:${AppwriteAccountManagement.defaultVerificationRedirectUrl}',
        ),
      );
    },
  );

  test('reloadUser refreshes the email verification state', () async {
    final account = FakeAppwriteAccount()
      ..setCurrent(
        const AppwriteAccountUser(
          id: 'user-1',
          email: 'user@kiln.dev',
          name: 'Kiln User',
          emailVerified: true,
          prefs: <String, Object?>{'photoUrl': 'https://cdn.kiln.dev/a.png'},
        ),
      );
    final management = AppwriteAccountManagement(account: account);

    expect(management.isEmailVerified, isFalse);
    await management.reloadUser();

    expect(management.isEmailVerified, isTrue);
    expect(management.displayName, 'Kiln User');
    expect(management.photoUrl, 'https://cdn.kiln.dev/a.png');
  });

  test('profile updates reach Appwrite', () async {
    final account = FakeAppwriteAccount();
    final management = AppwriteAccountManagement(account: account);

    await management.updateDisplayName('Tegar');
    await management.updatePhotoUrl('https://cdn.kiln.dev/t.png');

    expect(account.calls, contains('displayName:Tegar'));
    expect(account.calls, contains('photoUrl:https://cdn.kiln.dev/t.png'));
    expect(management.displayName, 'Tegar');
    expect(management.photoUrl, 'https://cdn.kiln.dev/t.png');
  });

  test('empty profile values are rejected before the call', () async {
    final account = FakeAppwriteAccount();
    final management = AppwriteAccountManagement(account: account);

    await expectLater(
      management.updateDisplayName('  '),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    expect(account.calls, isEmpty);
  });

  test('Appwrite failures become contract failures', () async {
    final account = FakeAppwriteAccount()
      ..failure = appwriteUnauthorizedFailure();
    final management = AppwriteAccountManagement(account: account);

    await expectLater(
      management.sendPasswordResetEmail('user@kiln.dev'),
      throwsA(
        isA<Failure>()
            .having(
              (failure) => failure.code,
              'code',
              FailureCode.authUnauthorized,
            )
            .having(
              (failure) => failure.kind,
              'kind',
              FailureKind.authentication,
            ),
      ),
    );
  });

  test('reloadUser fails when the session is gone', () async {
    final management = AppwriteAccountManagement(
      account: FakeAppwriteAccount(),
    );

    await expectLater(
      management.reloadUser(),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authSessionExpired,
        ),
      ),
    );
  });
}
