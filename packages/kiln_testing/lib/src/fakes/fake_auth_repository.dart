import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

/// In-memory [AuthRepository] with one known valid credential pair.
final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.validEmail = 'user@kiln.dev',
    this.validPassword = 'password123',
  });

  final String validEmail;
  final String validPassword;
  final List<String> calls = <String>[];
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
    calls.add('signIn:$email');
    if (email != validEmail || password != validPassword) {
      throw const Failure(
        code: FailureCode.authInvalidCredentials,
        message: 'Invalid email or password',
        kind: FailureKind.authentication,
      );
    }
    return _setSession(AuthSession(userId: email, email: email));
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    calls.add('signUp:$email');
    return _setSession(
      AuthSession(userId: email, email: email, displayName: displayName),
    );
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _session = null;
    _changes.add(null);
  }

  AuthSession _setSession(AuthSession session) {
    _session = session;
    _changes.add(session);
    return session;
  }

  Future<void> dispose() => _changes.close();
}
