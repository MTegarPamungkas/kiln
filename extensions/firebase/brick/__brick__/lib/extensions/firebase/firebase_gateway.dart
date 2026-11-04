import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:kiln_core/kiln_core.dart';

/// Provider-safe snapshot of a Firebase Auth user.
///
/// The SDK `User` type is mutable and plugin bound, so the gateway exposes
/// this immutable value to the rest of the extension.
final class FirebaseUser {
  const FirebaseUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.isAnonymous = false,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final bool isAnonymous;
}

/// Social providers Firebase Auth can drive itself.
enum FirebaseSocialProvider { google, apple }

/// Outcome of a provider sign-in, including the tokens Firebase issued.
final class FirebaseSocialResult {
  const FirebaseSocialResult({
    required this.user,
    required this.idToken,
    this.accessToken,
  });

  final FirebaseUser user;
  final String idToken;
  final String? accessToken;
}

/// Firebase Auth access that can be faked without a Firebase app.
abstract interface class FirebaseAuthGateway {
  FirebaseUser? get currentUser;

  Stream<FirebaseUser?> get authStateChanges;

  Future<FirebaseUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<FirebaseUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  Future<FirebaseSocialResult?> signInWithProvider(
    FirebaseSocialProvider provider,
  );

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  Future<void> reloadUser();

  Future<void> updateDisplayName(String? displayName);

  Future<void> updatePhotoUrl(String? photoUrl);

  Future<String?> idToken({bool forceRefresh = false});

  Future<void> useEmulator(String host, int port);
}

/// [FirebaseAuthGateway] backed by the `firebase_auth` plugin.
final class SdkFirebaseAuthGateway implements FirebaseAuthGateway {
  SdkFirebaseAuthGateway({this.firebaseAuth});

  auth.FirebaseAuth? firebaseAuth;

  auth.FirebaseAuth get _instance =>
      firebaseAuth ??= auth.FirebaseAuth.instance;

  @override
  FirebaseUser? get currentUser => _toUser(_instance.currentUser);

  @override
  Stream<FirebaseUser?> get authStateChanges =>
      _instance.authStateChanges().map(_toUser);

  @override
  Future<FirebaseUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _requireUser(credential.user);
  }

  @override
  Future<FirebaseUser> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    var user = _requireUser(credential.user);
    if (displayName != null && displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();
      user = _toUser(_instance.currentUser) ?? user;
    }
    return user;
  }

  @override
  Future<FirebaseSocialResult?> signInWithProvider(
    FirebaseSocialProvider provider,
  ) async {
    final auth.AuthProvider authProvider = switch (provider) {
      FirebaseSocialProvider.google => auth.GoogleAuthProvider(),
      FirebaseSocialProvider.apple => auth.AppleAuthProvider(),
    };
    final credential = await _instance.signInWithProvider(authProvider);
    final user = credential.user;
    if (user == null) {
      return null;
    }
    final idToken = await user.getIdToken() ?? '';
    return FirebaseSocialResult(
      user: _requireUser(user),
      idToken: idToken,
      accessToken: credential.credential?.accessToken,
    );
  }

  @override
  Future<void> signOut() => _instance.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _instance.sendPasswordResetEmail(email: email);

  @override
  Future<void> sendEmailVerification() async {
    final user = _instance.currentUser;
    if (user == null) {
      throw _missingUser();
    }
    await user.sendEmailVerification();
  }

  @override
  Future<void> reloadUser() async {
    final user = _instance.currentUser;
    if (user == null) {
      throw _missingUser();
    }
    await user.reload();
  }

  @override
  Future<void> updateDisplayName(String? displayName) async {
    final user = _instance.currentUser;
    if (user == null) {
      throw _missingUser();
    }
    await user.updateDisplayName(displayName);
  }

  @override
  Future<void> updatePhotoUrl(String? photoUrl) async {
    final user = _instance.currentUser;
    if (user == null) {
      throw _missingUser();
    }
    await user.updatePhotoURL(photoUrl);
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    return _instance.currentUser?.getIdToken(forceRefresh);
  }

  @override
  Future<void> useEmulator(String host, int port) =>
      _instance.useAuthEmulator(host, port);

  static FirebaseUser? _toUser(auth.User? user) {
    if (user == null) {
      return null;
    }
    return FirebaseUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      isAnonymous: user.isAnonymous,
    );
  }

  static FirebaseUser _requireUser(auth.User? user) {
    final converted = _toUser(user);
    if (converted == null) {
      throw _missingUser();
    }
    return converted;
  }

  static Failure _missingUser() {
    return const Failure(
      code: FailureCode.authUnauthorized,
      message: 'No Firebase user is currently signed in.',
      kind: FailureKind.authentication,
    );
  }
}
