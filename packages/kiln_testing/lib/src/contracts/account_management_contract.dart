import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

typedef AccountManagementContractFactory =
    FutureOr<AccountManagement> Function();

/// Behavior every [AccountManagement] implementation must share.
void accountManagementContract({
  required AccountManagementContractFactory create,
  String description = 'AccountManagement',
  String email = 'user@kiln.dev',
  String displayName = 'Kiln User',
}) {
  group('$description contract', () {
    test('reports the email verification state as a boolean', () async {
      final account = await create();

      expect(account.isEmailVerified, isA<bool>());
    });

    test('password reset and verification calls complete', () async {
      final account = await create();

      await account.sendPasswordResetEmail(email);
      await account.sendEmailVerification();
      await account.reloadUser();
    });

    test('profile updates complete', () async {
      final account = await create();

      await account.updateDisplayName(displayName);
      await account.updatePhotoUrl('https://cdn.kiln.dev/avatar.png');
    });
  });
}
