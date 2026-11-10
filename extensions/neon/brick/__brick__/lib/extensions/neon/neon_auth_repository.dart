// ignore_for_file: prefer_initializing_formals

import 'package:kiln_core/kiln_core.dart';

import 'neon_auth_gateway.dart';

/// [AuthRepository] backed by Neon Auth (Better Auth).
///
/// Email/password sessions are held by a shared [SessionController] so the app
/// observes sign-in state, and `accessJwt` on the gateway is what hands the
/// Data API its per-user bearer token.
final class NeonAuthRepository implements AuthRepository {
  NeonAuthRepository({
    required NeonAuthGateway gateway,
    required SessionController controller,
  }) : _gateway = gateway,
       _controller = controller;

  final NeonAuthGateway _gateway;
  final SessionController _controller;

  @override
  AuthSession? get currentSession => _controller.session;

  @override
  Stream<AuthSession?> get authStateChanges => _controller.sessionChanges;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final session = await _gateway.signIn(email: email, password: password);
    return _emit(session);
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final session = await _gateway.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    return _emit(session);
  }

  @override
  Future<void> signOut() async {
    await _gateway.signOut();
    _controller.markUnauthenticated();
  }

  /// Reconciles the controller with the stored session during bootstrap.
  Future<void> restore() async {
    final session = await _gateway.currentSession();
    if (session == null) {
      _controller.markUnauthenticated();
    } else {
      _emit(session);
    }
  }

  AuthSession _emit(NeonAuthSession session) {
    final value = AuthSession(
      userId: session.userId,
      email: session.email,
      displayName: session.displayName,
    );
    _controller.setSession(value);
    return value;
  }
}
