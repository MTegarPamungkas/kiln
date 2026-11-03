import 'dart:async';

import 'package:kiln_core/kiln_core.dart';

import 'jwt_expiry.dart';
import 'rest_token_store.dart';

/// Refreshes tokens once for any number of concurrent callers.
final class TokenRefresher implements TokenProvider {
  TokenRefresher({
    required this.store,
    required this.exchange,
    this.clock = const SystemClock(),
    this.leeway = const Duration(seconds: 30),
  });

  final RestTokenStore store;
  final Clock clock;
  final Duration leeway;
  final Future<AuthTokens?> Function(String refreshToken) exchange;
  Future<AuthTokens?>? _inFlight;

  @override
  Future<String?> accessToken({bool forceRefresh = false}) async {
    final stored = await store.read();
    if (!forceRefresh && stored != null && !_expired(stored)) {
      return stored.accessToken;
    }
    final refreshToken = stored?.refreshToken ?? await store.refreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }
    final refreshed = await refreshWith(refreshToken);
    return refreshed?.accessToken;
  }

  /// Refreshes once and shares the result with every waiting caller.
  Future<AuthTokens?> refreshWith(String refreshToken) {
    final existing = _inFlight;
    if (existing != null) {
      return existing;
    }
    final completer = Completer<AuthTokens?>();
    _inFlight = completer.future;
    () async {
      try {
        final tokens = await exchange(refreshToken);
        if (tokens != null) {
          await store.save(tokens);
        }
        completer.complete(tokens);
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _inFlight = null;
      }
    }();
    return completer.future;
  }

  @override
  Future<void> clear() => store.clear();

  bool _expired(AuthTokens tokens) {
    final expiresAt = tokens.expiresAt;
    if (expiresAt != null) {
      return !expiresAt.isAfter(clock.now().add(leeway));
    }
    return JwtExpiry.isExpired(tokens.accessToken, clock, leeway: leeway);
  }
}
