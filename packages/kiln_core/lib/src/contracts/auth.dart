import '../session/session.dart';

/// Email and password authentication, independent of the backend provider.
abstract interface class AuthRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> get authStateChanges;

  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> signOut();
}
