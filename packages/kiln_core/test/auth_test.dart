import 'dart:async';

import 'package:kiln_core/kiln_core.dart';
import 'package:test/test.dart';

final class _FakeAuthRepository implements AuthRepository {
  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast(sync: true);
  AuthSession? _session;

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> get authStateChanges => _changes.stream;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    if (password == 'wrong') {
      throw const Failure(
        code: FailureCode.authInvalidCredentials,
        message: 'Wrong credentials',
        kind: FailureKind.authentication,
      );
    }
    final session = AuthSession(userId: email, email: email);
    _session = session;
    _changes.add(session);
    return session;
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final session = AuthSession(
      userId: email,
      email: email,
      displayName: displayName,
    );
    _session = session;
    _changes.add(session);
    return session;
  }

  @override
  Future<void> signOut() async {
    _session = null;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}

void main() {
  group('AuthRepository contract', () {
    late _FakeAuthRepository auth;

    setUp(() {
      auth = _FakeAuthRepository();
    });

    tearDown(() async {
      await auth.dispose();
    });

    test('signIn returns a session and emits it', () async {
      final emitted = <AuthSession?>[];
      final subscription = auth.authStateChanges.listen(emitted.add);

      final session = await auth.signIn(
        email: 'user@kiln.dev',
        password: 'secret',
      );

      expect(session.userId, 'user@kiln.dev');
      expect(auth.currentSession, session);
      expect(emitted, [session]);
      await subscription.cancel();
    });

    test('signIn throws a Failure for wrong credentials', () async {
      await expectLater(
        auth.signIn(email: 'user@kiln.dev', password: 'wrong'),
        throwsA(
          isA<Failure>()
              .having(
                (failure) => failure.code,
                'code',
                FailureCode.authInvalidCredentials,
              )
              .having(
                (failure) => failure.isAuthFailure,
                'isAuthFailure',
                isTrue,
              ),
        ),
      );
      expect(auth.currentSession, isNull);
    });

    test(
      'signUp keeps the display name and signOut clears the session',
      () async {
        final session = await auth.signUp(
          email: 'new@kiln.dev',
          password: 'secret',
          displayName: 'New User',
        );

        expect(session.displayName, 'New User');

        await auth.signOut();
        expect(auth.currentSession, isNull);
      },
    );
  });

  group('AuthSession', () {
    test('reports expiry against a fixed clock with leeway', () {
      final clock = FixedClock(DateTime.utc(2026, 11, 1, 12));
      final session = AuthSession(
        userId: 'user',
        expiresAt: DateTime.utc(2026, 11, 1, 12, 5),
      );

      expect(session.isExpired(clock), isFalse);
      expect(
        session.isExpired(clock, leeway: const Duration(minutes: 10)),
        isTrue,
      );

      clock.advance(const Duration(minutes: 6));
      expect(session.isExpired(clock), isTrue);
    });
  });
}
