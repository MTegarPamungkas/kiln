import 'package:kiln_core/kiln_core.dart';

import 'firebase_failure_mapper.dart';
import 'firebase_gateway.dart';

/// [TokenProvider] that reads Firebase ID tokens on demand.
///
/// Tokens are never cached here: Firebase already caches them and refreshes
/// them shortly before expiry. Callers that receive a `401` pass
/// `forceRefresh: true` to obtain a new token.
final class FirebaseIdTokenProvider implements TokenProvider {
  const FirebaseIdTokenProvider({
    required this.gateway,
    this.failureMapper = mapFirebaseError,
  });

  final FirebaseAuthGateway gateway;
  final FirebaseFailureMapper failureMapper;

  @override
  Future<String?> accessToken({bool forceRefresh = false}) async {
    try {
      return await gateway.idToken(forceRefresh: forceRefresh);
    } catch (error, stackTrace) {
      throw failureMapper(error, stackTrace);
    }
  }

  @override
  Future<void> clear() async {
    // Firebase owns the token cache; signing out is what invalidates it.
  }
}
