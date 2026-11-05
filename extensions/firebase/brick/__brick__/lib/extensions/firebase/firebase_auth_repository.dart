import 'package:kiln_core/kiln_core.dart';

import 'firebase_failure_mapper.dart';
import 'firebase_gateway.dart';

/// Converts a gateway user into the identity held by [SessionController].
AuthSession? sessionForFirebaseUser(FirebaseUser? user) {
  if (user == null) {
    return null;
  }
  return AuthSession(
    userId: user.uid,
    email: user.email,
    displayName: user.displayName,
    metadata: <String, Object?>{
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      if (user.photoUrl != null) 'photoUrl': user.photoUrl,
    },
  );
}

/// [AuthRepository] backed by a [FirebaseAuthGateway].
final class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository({
    required this.gateway,
    this.failureMapper = mapFirebaseError,
  });

  final FirebaseAuthGateway gateway;
  final FirebaseFailureMapper failureMapper;

  @override
  AuthSession? get currentSession =>
      sessionForFirebaseUser(gateway.currentUser);

  @override
  Stream<AuthSession?> get authStateChanges =>
      gateway.authStateChanges.map(sessionForFirebaseUser);

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await gateway.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireSession(user);
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = await gateway.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      return _requireSession(user);
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await gateway.signOut();
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }

  AuthSession _requireSession(FirebaseUser user) {
    final session = sessionForFirebaseUser(user);
    if (session == null) {
      throw const Failure(
        code: FailureCode.authUnauthorized,
        message: 'Firebase did not return a user session.',
        kind: FailureKind.authentication,
      );
    }
    return session;
  }
}

/// [SocialAuth] that lets Firebase Auth drive the native provider flow.
final class FirebaseSocialAuth implements SocialAuth {
  const FirebaseSocialAuth({
    required this.gateway,
    this.failureMapper = mapFirebaseError,
  });

  final FirebaseAuthGateway gateway;
  final FirebaseFailureMapper failureMapper;

  @override
  Future<SocialCredential?> signIn(SocialProvider provider) async {
    try {
      final result = await gateway.signInWithProvider(switch (provider) {
        SocialProvider.google => FirebaseSocialProvider.google,
        SocialProvider.apple => FirebaseSocialProvider.apple,
      });
      if (result == null) {
        return null;
      }
      return SocialCredential(
        provider: provider,
        idToken: result.idToken,
        accessToken: result.accessToken,
        email: result.user.email,
        displayName: result.user.displayName,
      );
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await gateway.signOut();
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }
}
