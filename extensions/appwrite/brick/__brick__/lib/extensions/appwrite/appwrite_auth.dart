import 'package:kiln_core/kiln_core.dart';

import 'appwrite_account.dart';
import 'appwrite_failure_mapper.dart';
import 'appwrite_session_bridge.dart';

/// [AuthRepository] on top of the Appwrite `Account` service.
final class AppwriteAuth implements AuthRepository {
  AppwriteAuth({
    required this.account,
    required this.bridge,
    AppwriteFailureMapper failureMapper = const AppwriteFailureMapper(),
  }) : _failures = failureMapper;

  final AppwriteAccount account;
  final AppwriteSessionBridge bridge;
  final AppwriteFailureMapper _failures;

  @override
  AuthSession? get currentSession => bridge.session;

  @override
  Stream<AuthSession?> get authStateChanges => bridge.changes;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final result = await account.signIn(email: email, password: password);
      return bridge.establish(user: result.user, session: result.session);
    });
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _guard(() async {
      await account.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      final result = await account.signIn(email: email, password: password);
      return bridge.establish(user: result.user, session: result.session);
    });
  }

  @override
  Future<void> signOut() async {
    Object? failure;
    StackTrace? failureStack;
    try {
      await account.signOut();
    } on Object catch (error, stackTrace) {
      failure = error;
      failureStack = stackTrace;
    }
    bridge.clear();
    if (failure != null) {
      throw _failures.map(
        failure,
        scope: AppwriteFailureScope.auth,
        stackTrace: failureStack,
      );
    }
  }

  /// Restores an Appwrite session that outlived the last app launch.
  ///
  /// Call this during the splash screen; a missing or expired session clears
  /// the local state instead of throwing.
  Future<void> restoreSession() async {
    try {
      final user = await account.currentUser();
      if (user == null) {
        bridge.clear();
        return;
      }
      bridge.establish(user: user);
    } on Object catch (error, stackTrace) {
      final failure = _failures.map(
        error,
        scope: AppwriteFailureScope.auth,
        stackTrace: stackTrace,
      );
      if (failure.code == FailureCode.authUnauthorized ||
          failure.code == FailureCode.authSessionExpired) {
        bridge.clear();
        return;
      }
      throw failure;
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on Object catch (error, stackTrace) {
      throw _failures.map(
        error,
        scope: AppwriteFailureScope.auth,
        stackTrace: stackTrace,
      );
    }
  }
}
