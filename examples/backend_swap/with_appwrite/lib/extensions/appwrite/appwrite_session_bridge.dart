import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'appwrite_account.dart';
import 'appwrite_failure_mapper.dart';

/// Keeps [SessionController] and [TokenProvider] in sync with Appwrite.
final class AppwriteSessionBridge {
  AppwriteSessionBridge({this.controller, this.tokenProvider});

  /// Application session state, when the app bootstrapped a controller.
  final SessionController? controller;

  /// Provider that mints Appwrite JWTs for outgoing requests.
  final TokenProvider? tokenProvider;

  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast(sync: true);
  AuthSession? _session;
  int _revision = 0;
  bool _disposed = false;

  /// Changes when local authentication state is replaced or disposed.
  int get revision => _revision;

  /// Invalidates older restore/login results without publishing a session yet.
  int beginOperation() {
    if (_disposed) {
      throw const Failure(
        code: FailureCode.unavailable,
        message: 'The Appwrite session bridge is disposed.',
        kind: FailureKind.authentication,
      );
    }
    return ++_revision;
  }

  AuthSession? get session => _session;

  /// Emits every session change. Register a listener before signing in; the
  /// current session is available from [session].
  Stream<AuthSession?> get changes => _changes.stream;

  /// Publishes the Appwrite user as the active application session.
  AuthSession establish({
    required AppwriteAccountUser user,
    AppwriteAccountSession? session,
  }) {
    if (_disposed) {
      throw const Failure(
        code: FailureCode.unavailable,
        message: 'The Appwrite session bridge is disposed.',
        kind: FailureKind.authentication,
      );
    }
    _revision++;
    final resolved = AuthSession(
      userId: user.id,
      email: user.email.isEmpty ? null : user.email,
      displayName: user.displayName,
      expiresAt: session?.expiresAt,
      metadata: <String, Object?>{
        if (session != null && session.id.isNotEmpty)
          'appwriteSessionId': session.id,
      },
    );
    _session = resolved;
    controller?.setSession(resolved);
    final tokens = tokenProvider;
    if (tokens != null) {
      unawaited(tokens.clear());
    }
    _changes.add(resolved);
    return resolved;
  }

  /// Clears the session locally after sign-out or an expired Appwrite session.
  void clear() {
    if (_disposed) return;
    _revision++;
    _session = null;
    controller?.markUnauthenticated();
    final tokens = tokenProvider;
    if (tokens != null) {
      unawaited(tokens.clear());
    }
    _changes.add(null);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _revision++;
    _session = null;
    await tokenProvider?.clear();
    await _changes.close();
  }
}

/// [TokenProvider] backed by short-lived Appwrite JWTs.
final class AppwriteTokenProvider implements TokenProvider {
  AppwriteTokenProvider({
    required this.account,
    this.lifetime = const Duration(minutes: 14),
    this.clock = const SystemClock(),
  });

  final AppwriteAccount account;

  /// Cached lifetime; Appwrite JWTs expire after 15 minutes.
  final Duration lifetime;
  final Clock clock;

  final AppwriteFailureMapper _failures = const AppwriteFailureMapper();
  String? _token;
  DateTime? _expiresAt;
  int _generation = 0;
  Future<String?>? _pending;

  @override
  Future<String?> accessToken({bool forceRefresh = false, DateTime? deadline}) {
    final expiresAt = _expiresAt;
    if (!forceRefresh &&
        _token != null &&
        expiresAt != null &&
        expiresAt.isAfter(clock.now())) {
      return Future.value(_token);
    }
    final pending = _pending;
    if (pending != null) return pending;
    late final Future<String?> request;
    request = _mint(_generation).whenComplete(() {
      if (identical(_pending, request)) _pending = null;
    });
    _pending = request;
    return request;
  }

  Future<String?> _mint(int generation) async {
    final requestedAt = clock.now();
    try {
      final token = await account.createJwt();
      if (generation != _generation) return null;
      if (token == null || token.isEmpty) {
        _token = null;
        _expiresAt = null;
        return null;
      }
      _token = token;
      _expiresAt = requestedAt.add(lifetime);
      return token;
    } on Object catch (error, stackTrace) {
      if (generation != _generation) return null;
      _token = null;
      _expiresAt = null;
      final failure = _failures.map(
        error,
        scope: AppwriteFailureScope.auth,
        stackTrace: stackTrace,
      );
      if (failure.code == FailureCode.authUnauthorized ||
          failure.code == FailureCode.authSessionExpired) {
        return null;
      }
      throw failure;
    }
  }

  @override
  Future<void> clear() async {
    _generation++;
    _pending = null;
    _token = null;
    _expiresAt = null;
  }
}
