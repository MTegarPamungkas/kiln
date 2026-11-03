import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_supabase/extensions/supabase/supabase_account_management.dart';

import 'test_support.dart';

void main() {
  late FakeSupabaseGateway gateway;
  late SupabaseAccountManagement account;

  setUp(() {
    gateway = FakeSupabaseGateway();
    account = SupabaseAccountManagement(
      gateway: gateway,
      redirectUri: Uri.parse('kiln-auth://auth-callback'),
    );
  });

  test('sendPasswordResetEmail meneruskan email dan redirect', () async {
    await account.sendPasswordResetEmail('user@kiln.dev');

    expect(gateway.resetEmails, ['user@kiln.dev']);
    expect(gateway.lastResetRedirect, 'kiln-auth://auth-callback');
  });

  test('sendPasswordResetEmail menolak email tidak valid', () async {
    await expectLater(
      account.sendPasswordResetEmail('bukan-email'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
    expect(gateway.resetEmails, isEmpty);
  });

  test('sendEmailVerification memakai redirect callback', () async {
    await account.sendEmailVerification();

    expect(gateway.lastVerificationRedirect, 'kiln-auth://auth-callback');
  });

  test('isEmailVerified mengikuti sesi aktif', () async {
    expect(account.isEmailVerified, isFalse);

    await gateway.signInWithPassword(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    expect(account.isEmailVerified, isTrue);
  });

  test(
    'reloadUser memuat ulang user dan memperbarui status verifikasi',
    () async {
      gateway.verifyOnSignIn = false;
      await gateway.signInWithPassword(
        email: 'user@kiln.dev',
        password: 'password123',
      );
      expect(account.isEmailVerified, isFalse);

      gateway.verifyOnRefresh = true;
      await account.reloadUser();

      expect(gateway.refreshUserCalls, 1);
      expect(account.isEmailVerified, isTrue);
    },
  );

  test('updateDisplayName mengirim data display_name', () async {
    await account.updateDisplayName('  Tegar  ');

    expect(gateway.updatedUsers, [
      <String, Object?>{'display_name': 'Tegar'},
    ]);
  });

  test('updateDisplayName menolak nama kosong', () async {
    await expectLater(
      account.updateDisplayName('   '),
      throwsA(
        isA<Failure>().having(
          (value) => value.kind,
          'kind',
          FailureKind.validation,
        ),
      ),
    );
    expect(gateway.updatedUsers, isEmpty);
  });

  test('updatePhotoUrl mengirim avatar_url dan bisa menghapusnya', () async {
    await account.updatePhotoUrl('https://cdn.kiln.dev/a.png');
    await account.updatePhotoUrl(null);

    expect(
      gateway.updatedUsers.first['avatar_url'],
      'https://cdn.kiln.dev/a.png',
    );
    expect(gateway.updatedUsers.last.containsKey('avatar_url'), isTrue);
    expect(gateway.updatedUsers.last['avatar_url'], isNull);
  });

  test('updatePhotoUrl menolak teks kosong', () async {
    await expectLater(
      account.updatePhotoUrl(''),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.validationInvalidInput,
        ),
      ),
    );
  });
}
