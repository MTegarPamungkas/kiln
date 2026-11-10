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
  Future<void> _writes = Future<void>.value();
  int _generation = 0;

  @override
  Future<String?> accessToken({bool forceRefresh = false}) async {
    final generation = _generation;
    final stored = await store.read();
    if (generation != _generation) {
      return null;
    }
    if (!forceRefresh && stored != null && !_expired(stored)) {
      return stored.accessToken;
    }
    final refreshToken = stored?.refreshToken ?? await store.refreshToken();
    if (generation != _generation || refreshToken == null || refreshToken.isEmpty) {
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
    final generation = _generation;
    _inFlight = completer.future;
    () async {
      try {
        final tokens = await exchange(refreshToken);
        if (tokens != null) {
          await _updateStore(() async {
            if (generation == _generation) {
              await store.save(tokens);
            }
          });
        }
        completer.complete(generation == _generation ? tokens : null);
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        if (identical(_inFlight, completer.future)) {
          _inFlight = null;
        }
      }
    }();
    return completer.future;
  }

  @override
  Future<void> clear() {
    _generation++;
    _inFlight = null;
    return _updateStore(store.clear);
  }

  Future<void> _updateStore(Future<void> Function() update) {
    // Clearing never waits for the network, but follows any ongoing token write.
    final operation = _writes.then((_) => update());
    _writes = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }

  bool _expired(AuthTokens tokens) {
    final expiresAt = tokens.expiresAt;
    if (expiresAt != null) {
      return !expiresAt.isAfter(clock.now().add(leeway));
    }
    return JwtExpiry.isExpired(tokens.accessToken, clock, leeway: leeway);
  }
}
