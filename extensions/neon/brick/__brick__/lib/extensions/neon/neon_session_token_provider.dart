import 'neon_auth_gateway.dart';
import 'neon_token_provider.dart';

/// Prefers the signed-in user's JWT, falling back to an anonymous or static
/// token when the user is signed out. This keeps `remote_database` authorized
/// across both states.
final class NeonSessionTokenProvider implements DisposableNeonTokenProvider {
  NeonSessionTokenProvider({required this.auth, this.fallback});

  final NeonAuthGateway auth;
  final NeonTokenProvider? fallback;

  @override
  Future<String?> token() async =>
      await auth.accessJwt() ?? await fallback?.token();

  /// Releases the fallback provider's resources when it holds any, so a
  /// signed-in session does not leak the anonymous provider's HTTP client.
  @override
  void close() {
    final fallback = this.fallback;
    if (fallback is DisposableNeonTokenProvider) {
      fallback.close();
    }
  }
}
