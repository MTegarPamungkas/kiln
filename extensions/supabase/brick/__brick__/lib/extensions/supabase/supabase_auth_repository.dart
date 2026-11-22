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
  int _generation = 0;
  bool _disposed = false;
  bool _locallySignedOut = false;
  Future<void> _commits = Future<void>.value();

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
    final generation = ++_generation;
    final session = await _call(_gateway.restoreSession);
    return _commit(session, generation);
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    _start();
    final generation = ++_generation;
    final session = await _call(
      () => _gateway.signInWithPassword(email: email, password: password),
    );
    final committed = await _commit(session, generation);
    return committed!;
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _start();
    final generation = ++_generation;
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
    final committed = await _commit(session, generation);
    return committed!;
  }

  @override
  Future<void> signOut() async {
    _start();
    ++_generation;
    _locallySignedOut = true;
    await _serialize(() async {
      _apply(null);
    });
    try {
      await _call(_gateway.signOut);
    } on Object {
      // Signing out must succeed offline; the adapter already cleared its
      // local session and ignores stale SDK events from the failed attempt.
    }
  }

  /// Cancels the session subscription and closes the stream.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
    await _changes.close();
  }

  void _start() {
    if (_disposed) {
      return;
    }
    _subscription ??= _gateway.authStateChanges.listen(
      (session) {
        // A failed remote sign-out must not resurrect the old user through a
        // delayed SDK event.
        if (_locallySignedOut && session != null) {
          return;
        }
        _apply(session);
      },
      onError: (Object error, StackTrace stackTrace) {
        // Keep the last known session; a failed refresh is reported by the
        // next request that uses the token.
      },
    );
  }

  Future<AuthSession?> _commit(SupabaseSession? session, int generation) {
    return _serialize(() async {
      if (_disposed || generation != _generation) {
        throw const Failure(
          code: FailureCode.authCancelled,
          message: 'The session changed while the request was in flight.',
          kind: FailureKind.authentication,
        );
      }
      _locallySignedOut = false;
      _apply(session);
      return currentSession;
    });
  }

  /// Runs session writes in order so late results cannot interleave.
  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _commits.then((_) => action());
    _commits = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  void _apply(SupabaseSession? session) {
    if (_disposed || _session == session) {
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
/// Null means the user cancelled the account picker. Prefer
/// [SupabaseCredentialSource], which also carries the raw nonce and
/// authorization code that Apple exchanges need.
typedef SupabaseIdTokenSource = Future<String?> Function(
  SocialProvider provider,
);

/// Source of a full native credential for the Supabase ID-token exchange.
///
/// The credential must use [SocialTokenAudience.provider]; its [rawNonce] and
/// [authorizationCode] are forwarded to Supabase when present.
typedef SupabaseCredentialSource = Future<SocialCredential?> Function(
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
    SupabaseCredentialSource? credentialSource,
  }) : _gateway = gateway,
       _config = config,
       _idTokenSource = idTokenSource,
       _credentialSource = credentialSource;

  final SupabaseGateway _gateway;
  final SupabaseConfig _config;
  final SupabaseIdTokenSource? _idTokenSource;
  final SupabaseCredentialSource? _credentialSource;

  @override
  Future<SocialCredential?> signIn(SocialProvider provider) async {
    final credentialSource = _credentialSource;
    if (credentialSource != null) {
      final credential = await _call(() => credentialSource(provider));
      if (credential == null) {
        return null;
      }
      if (credential.audience != SocialTokenAudience.provider) {
        throw const Failure(
          code: FailureCode.validationUnsupportedValue,
          message:
              'The Supabase ID-token exchange requires provider credentials, '
              'not a backend session.',
          kind: FailureKind.validation,
        );
      }
      final session = await _call(
        () => _gateway.signInWithIdToken(
          provider: provider,
          idToken: credential.idToken,
          accessToken: credential.accessToken,
          nonce: credential.rawNonce,
        ),
      );
      return credential.copyWith(
        backendSessionToken: session.accessToken,
        email: credential.email ?? session.email,
        displayName: credential.displayName ?? session.displayName,
      );
    }

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
        backendSessionToken: session.accessToken,
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
    // A session that existed before this flow must not count as its result.
    final before = _gateway.currentSession;
    final launched = await _call(
      () =>
          _gateway.signInWithOAuth(provider: provider, redirectTo: redirectTo),
    );
    if (!launched) {
      return null;
    }
    final session = await _waitForNewSession(before);
    final token = session?.accessToken;
    if (session == null || token == null || token.isEmpty) {
      return null;
    }
    // The provider verified the identity on the Supabase server; the token
    // available here is the Supabase session, not a provider identity token.
    return SocialCredential(
      provider: provider,
      idToken: token,
      audience: SocialTokenAudience.backend,
      backendSessionToken: token,
      email: session.email,
      displayName: session.displayName,
    );
  }

  @override
  Future<void> signOut() => _call(_gateway.signOut);

  Future<SupabaseSession?> _waitForNewSession(SupabaseSession? before) async {
    final current = _gateway.currentSession;
    if (current != null && !_sameSession(before, current)) {
      return current;
    }
    final completer = Completer<SupabaseSession?>();
    final subscription = _gateway.authStateChanges.listen(
      (session) {
        if (session != null &&
            !completer.isCompleted &&
            !_sameSession(before, session)) {
          completer.complete(session);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    try {
      return await completer.future.timeout(
        _config.authTimeout,
        onTimeout: () => null,
      );
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(
        error,
        stackTrace: stackTrace,
        fallbackCode: FailureCode.authUnauthorized,
        fallbackKind: FailureKind.authentication,
      );
    } finally {
      await subscription.cancel();
    }
  }

  bool _sameSession(SupabaseSession? before, SupabaseSession session) {
    final previous = before;
    if (previous == null) {
      return false;
    }
    return previous.userId == session.userId &&
        previous.accessToken == session.accessToken;
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
