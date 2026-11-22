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
      final revision = bridge.beginOperation();
      final AppwriteAuthResult result;
      try {
        result = await account.signIn(email: email, password: password);
      } catch (_) {
        if (revision == bridge.revision) bridge.clear();
        rethrow;
      }
      _ensureCurrent(revision);
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
      final revision = bridge.beginOperation();
      await account.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _ensureCurrent(revision);
      final result = await account.signIn(email: email, password: password);
      _ensureCurrent(revision);
      return bridge.establish(user: result.user, session: result.session);
    });
  }

  @override
  Future<void> signOut() async {
    bridge.clear();
    Object? failure;
    StackTrace? failureStack;
    try {
      await account.signOut();
    } on Object catch (error, stackTrace) {
      failure = error;
      failureStack = stackTrace;
    }
    if (failure != null) {
      final mapped = _failures.map(
        failure,
        scope: AppwriteFailureScope.auth,
        stackTrace: failureStack,
      );
      if (mapped.kind != FailureKind.network) throw mapped;
    }
  }

  /// Restores an Appwrite session that outlived the last app launch.
  ///
  /// Call this during the splash screen; a missing or expired session clears
  /// the local state instead of throwing.
  Future<void> restoreSession() async {
    final revision = bridge.revision;
    try {
      final user = await account.currentUser();
      if (revision != bridge.revision) return;
      if (user == null) {
        bridge.clear();
        return;
      }
      bridge.establish(user: user);
    } on Object catch (error, stackTrace) {
      if (revision != bridge.revision) return;
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
      if (failure.details['localCleanupFailed'] == true) bridge.clear();
      throw failure;
    }
  }

  void _ensureCurrent(int revision) {
    if (revision != bridge.revision) {
      throw const Failure(
        code: FailureCode.authCancelled,
        message: 'The authentication operation was superseded.',
        kind: FailureKind.authentication,
      );
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
