// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'supabase_config.dart';
import 'supabase_failure_mapper.dart';
import 'supabase_gateway.dart';

/// [AuthRepository] implementation on top of Supabase Auth.
///
/// The session is cached in memory so [currentSession] is available right
/// after `signIn`, and every gateway change is forwarded to
/// [authStateChanges].
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required SupabaseGateway gateway, Uri? redirectUri})
    : _gateway = gateway,
      redirectUri = redirectUri;

  final SupabaseGateway _gateway;

  /// Email confirmation and password reset URL sent to Supabase.
  final Uri? redirectUri;

  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast(sync: true);
  StreamSubscription<SupabaseSession?>? _subscription;
  SupabaseSession? _session;

  @override
  AuthSession? get currentSession {
    final session = _session;
    return session == null ? null : _toAuthSession(session);
  }

  @override
  Stream<AuthSession?> get authStateChanges {
    _start();
    return _changes.stream;
  }

  /// Reads the stored session into [currentSession].
  ///
  /// Called by the module from the `ready` hook once the Supabase client is
  /// ready.
  Future<AuthSession?> restore() async {
    _start();
    final session = await _call(_gateway.restoreSession);
    _apply(session);
    return currentSession;
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    _start();
    final session = await _call(
      () => _gateway.signInWithPassword(email: email, password: password),
    );
    _apply(session);
    return _toAuthSession(session);
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _start();
    final session = await _call(
      () => _gateway.signUp(
        email: email,
        password: password,
        displayName: displayName,
        redirectTo: redirectUri?.toString(),
      ),
    );
    if (session == null) {
      throw const Failure(
        code: FailureCode.authEmailNotVerified,
        message: 'Sign-up succeeded. Confirm the email before signing in.',
        kind: FailureKind.authentication,
      );
    }
    _apply(session);
    return _toAuthSession(session);
  }

  @override
  Future<void> signOut() async {
    _start();
    await _call(_gateway.signOut);
    _apply(null);
  }

  /// Cancels the session subscription and closes the stream.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _changes.close();
  }

  void _start() {
    _subscription ??= _gateway.authStateChanges.listen(
      _apply,
      onError: (Object error, StackTrace stackTrace) {
        // Keep the last known session; a failed refresh is reported by the
        // next request that uses the token.
      },
    );
  }

  void _apply(SupabaseSession? session) {
    if (_session == session) {
      return;
    }
    _session = session;
    if (!_changes.isClosed) {
      _changes.add(currentSession);
    }
  }

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: FailureCode.authUnauthorized,
        fallbackKind: FailureKind.authentication,
      );
    }
  }

  AuthSession _toAuthSession(SupabaseSession session) {
    return AuthSession(
      userId: session.userId,
      email: session.email,
      displayName: session.displayName,
      expiresAt: session.expiresAt,
      metadata: <String, Object?>{
        ...session.metadata,
        'email_verified': session.emailVerified,
      },
    );
  }
}

/// Source of an ID token from a social SDK such as Google Sign-In or Apple.
///
/// Null means the user cancelled the account picker.
typedef SupabaseIdTokenSource = Future<String?> Function(
  SocialProvider provider,
);

/// [SocialAuth] implementation on top of Supabase.
///
/// When [idTokenSource] is available the social ID token is exchanged for a
/// Supabase session with `signInWithIdToken`. Without that source the
/// extension opens the OAuth flow in the browser and waits for the session
/// from the deep link callback.
final class SupabaseSocialAuth implements SocialAuth {
  SupabaseSocialAuth({
    required SupabaseGateway gateway,
    required SupabaseConfig config,
    SupabaseIdTokenSource? idTokenSource,
  }) : _gateway = gateway,
       _config = config,
       _idTokenSource = idTokenSource;

  final SupabaseGateway _gateway;
  final SupabaseConfig _config;
  final SupabaseIdTokenSource? _idTokenSource;

  @override
  Future<SocialCredential?> signIn(SocialProvider provider) async {
    final source = _idTokenSource;
    if (source != null) {
      final idToken = await _call(() => source(provider));
      if (idToken == null || idToken.isEmpty) {
        return null;
      }
      final session = await _call(
        () => _gateway.signInWithIdToken(provider: provider, idToken: idToken),
      );
      return SocialCredential(
        provider: provider,
        idToken: idToken,
        accessToken: session.accessToken,
        email: session.email,
        displayName: session.displayName,
      );
    }

    final redirectTo = _config.redirectUri?.toString();
    if (redirectTo == null) {
      throw const Failure(
        code: FailureCode.configurationInvalid,
        message: 'authRedirectUrl is required to sign in through the browser.',
        kind: FailureKind.configuration,
      );
    }
    final launched = await _call(
      () =>
          _gateway.signInWithOAuth(provider: provider, redirectTo: redirectTo),
    );
    if (!launched) {
      return null;
    }
    final session = _gateway.currentSession ?? await _waitForSession();
    final token = session?.accessToken;
    if (session == null || token == null || token.isEmpty) {
      return null;
    }
    // The provider verifies the identity on the Supabase server, so the token
    // available to callers is the access token of the resulting OAuth session.
    return SocialCredential(
      provider: provider,
      idToken: token,
      accessToken: token,
      email: session.email,
      displayName: session.displayName,
    );
  }

  @override
  Future<void> signOut() => _call(_gateway.signOut);

  Future<SupabaseSession?> _waitForSession() async {
    try {
      return await _gateway.authStateChanges
          .where((session) => session != null)
          .first
          .timeout(_config.authTimeout);
    } on TimeoutException {
      return null;
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: FailureCode.authUnauthorized,
        fallbackKind: FailureKind.authentication,
      );
    }
  }

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: FailureCode.authUnauthorized,
        fallbackKind: FailureKind.authentication,
      );
    }
  }
}
