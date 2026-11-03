import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_supabase/extensions/supabase/supabase_auth_repository.dart';
import 'package:with_supabase/extensions/supabase/supabase_gateway.dart';

import 'test_support.dart';

void main() {
  late FakeSupabaseGateway gateway;
  late SupabaseAuthRepository auth;

  setUp(() {
    gateway = FakeSupabaseGateway();
    auth = SupabaseAuthRepository(
      gateway: gateway,
      redirectUri: Uri.parse('kiln-auth://auth-callback'),
    );
  });

  test('signIn menyimpan sesi dan meneruskannya ke authStateChanges', () async {
    final emitted = <AuthSession?>[];
    final subscription = auth.authStateChanges.listen(emitted.add);

    final session = await auth.signIn(
      email: 'user@kiln.dev',
      password: 'password123',
    );

    expect(session.userId, 'user-1');
    expect(session.email, 'user@kiln.dev');
    expect(session.displayName, 'Demo User');
    expect(session.metadata['email_verified'], isTrue);
    expect(auth.currentSession, isNotNull);
    expect(gateway.signedInEmails, ['user@kiln.dev']);
    expect(emitted, isNotEmpty);
    expect(emitted.last?.userId, session.userId);

    await subscription.cancel();
    await auth.dispose();
  });

  test('signIn dengan kredensial salah menjadi Failure auth', () async {
    await expectLater(
      auth.signIn(email: 'user@kiln.dev', password: 'wrong-password'),
      throwsA(
        isA<Failure>()
            .having((value) => value.kind, 'kind', FailureKind.authentication)
            .having(
              (value) => value.code,
              'code',
              FailureCode.authInvalidCredentials,
            ),
      ),
    );
    expect(auth.currentSession, isNull);
    await auth.dispose();
  });

  test('signUp meneruskan displayName dan redirectUri', () async {
    final session = await auth.signUp(
      email: 'new@kiln.dev',
      password: 'password123',
      displayName: 'New User',
    );

    expect(session.displayName, 'New User');
    expect(gateway.signedUpDisplayNames, ['New User']);
    expect(gateway.lastEmailRedirect, 'kiln-auth://auth-callback');
    await auth.dispose();
  });

  test('signUp tanpa sesi berarti menunggu konfirmasi email', () async {
    gateway.requireEmailConfirmation = true;

    await expectLater(
      auth.signUp(email: 'new@kiln.dev', password: 'password123'),
      throwsA(
        isA<Failure>().having(
          (value) => value.code,
          'code',
          FailureCode.authEmailNotVerified,
        ),
      ),
    );
    expect(auth.currentSession, isNull);
    await auth.dispose();
  });

  test('signOut membersihkan sesi dan mengirim null', () async {
    await auth.signIn(email: 'user@kiln.dev', password: 'password123');
    final emitted = <AuthSession?>[];
    final subscription = auth.authStateChanges.listen(emitted.add);

    await auth.signOut();

    expect(auth.currentSession, isNull);
    expect(gateway.signOutCalls, 1);
    expect(emitted, contains(null));

    await subscription.cancel();
    await auth.dispose();
  });

  test('restore memakai sesi yang sudah ada di gateway', () async {
    gateway.initialSession = const SupabaseSession(
      userId: 'user-9',
      email: 'stored@kiln.dev',
      displayName: 'Stored',
      accessToken: 'stored-token',
    );

    final session = await auth.restore();

    expect(session?.userId, 'user-9');
    expect(session?.displayName, 'Stored');
    expect(auth.currentSession?.userId, 'user-9');
    await auth.dispose();
  });

  test('authStateChanges dari gateway diteruskan tanpa duplikasi', () async {
    final emitted = <AuthSession?>[];
    final subscription = auth.authStateChanges.listen(emitted.add);

    await gateway.signInWithPassword(
      email: 'push@kiln.dev',
      password: 'password123',
    );

    expect(auth.currentSession?.email, 'push@kiln.dev');
    expect(emitted.length, 1);

    await subscription.cancel();
    await auth.dispose();
  });
}
