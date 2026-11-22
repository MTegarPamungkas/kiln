import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_auth_repository.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_config.dart';
import 'package:{{app_name}}/extensions/supabase/supabase_gateway.dart';

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

  test('signIn stores the session and forwards it to authStateChanges', () async {
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

  test('signIn with wrong credentials becomes an auth Failure', () async {
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

  test('signUp forwards displayName and redirectUri', () async {
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

  test('signUp without a session waits for email confirmation', () async {
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

  test('signOut clears the session and emits null', () async {
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

  test('restore uses the session already in the gateway', () async {
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

  test('a delayed restore cannot win after signOut', () async {
    gateway.initialSession = const SupabaseSession(userId: 'user-9');
    gateway.restoreGate = Completer<void>();
    final restore = auth.restore();
    await Future<void>.delayed(Duration.zero);
    await auth.signOut();
    gateway.restoreGate!.complete();

    await expectLater(
      restore,
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authCancelled,
        ),
      ),
    );
    expect(auth.currentSession, isNull);
    await auth.dispose();
  });

  test('a delayed signIn cannot win after signOut', () async {
    gateway.signInGate = Completer<void>();
    final login = auth.signIn(
      email: 'user@kiln.dev',
      password: 'password123',
    );
    await Future<void>.delayed(Duration.zero);
    await auth.signOut();
    gateway.signInGate!.complete();

    await expectLater(
      login,
      throwsA(
        isA<Failure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.authCancelled,
        ),
      ),
    );
    expect(auth.currentSession, isNull);
    await auth.dispose();
  });

  test('signOut clears local state even when the remote call fails', () async {
    await auth.signIn(email: 'user@kiln.dev', password: 'password123');
    gateway.signOutFailure = StateError('offline');

    await auth.signOut();

    expect(auth.currentSession, isNull);
    await auth.dispose();
  });

  group('SupabaseSocialAuth', () {
    SupabaseSocialAuth social({
      SupabaseConfig? config,
      SupabaseCredentialSource? credentialSource,
      SupabaseIdTokenSource? idTokenSource,
    }) {
      return SupabaseSocialAuth(
        gateway: gateway,
        config: config ?? testConfig(),
        credentialSource: credentialSource,
        idTokenSource: idTokenSource,
      );
    }

    test('exchanges a provider credential and keeps the backend token separate',
        () async {
      final result = await social(
        credentialSource: (provider) async => SocialCredential(
          provider: provider,
          idToken: 'provider-token',
          rawNonce: 'raw-nonce',
        ),
      ).signIn(SocialProvider.apple);

      expect(gateway.idTokenNonces, ['raw-nonce']);
      expect(result?.audience, SocialTokenAudience.provider);
      expect(result?.idToken, 'provider-token');
      expect(result?.accessToken, isNull);
      expect(result?.backendSessionToken, 'access-token');
      expect(result?.rawNonce, 'raw-nonce');
    });

    test('rejects a backend-audience credential before the exchange', () async {
      await expectLater(
        social(
          credentialSource: (provider) async => SocialCredential(
            provider: provider,
            idToken: 'backend-token',
            audience: SocialTokenAudience.backend,
          ),
        ).signIn(SocialProvider.google),
        throwsA(
          isA<Failure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.validationUnsupportedValue,
          ),
        ),
      );
      expect(gateway.idTokenProviders, isEmpty);
    });

    test('the legacy id-token source keeps the backend token separate',
        () async {
      final result = await social(
        idTokenSource: (_) async => 'provider-token',
      ).signIn(SocialProvider.google);

      expect(result?.audience, SocialTokenAudience.provider);
      expect(result?.idToken, 'provider-token');
      expect(result?.accessToken, isNull);
      expect(result?.backendSessionToken, 'access-token');
    });

    test('a prior session is not reported as the result of a new OAuth flow',
        () async {
      await gateway.signInWithPassword(
        email: 'prior@kiln.dev',
        password: 'password123',
      );
      gateway.emitOAuthSession = false;

      final result = await social(
        config: const SupabaseConfig(
          url: 'https://demo.supabase.co',
          anonKey: 'anon-key',
          authTimeout: Duration(milliseconds: 50),
        ),
      ).signIn(SocialProvider.google);

      expect(result, isNull);
    });

    test('a new OAuth session is returned with backend audience', () async {
      await gateway.signInWithPassword(
        email: 'prior@kiln.dev',
        password: 'password123',
      );
      gateway.oauthSession = const SupabaseSession(
        userId: 'user-2',
        email: 'new@kiln.dev',
        accessToken: 'new-token',
      );

      final result = await social().signIn(SocialProvider.google);

      expect(result?.audience, SocialTokenAudience.backend);
      expect(result?.backendSessionToken, 'new-token');
      expect(result?.idToken, 'new-token');
      expect(result?.email, 'new@kiln.dev');
    });
  });

  test('gateway authStateChanges forward without duplication', () async {
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
