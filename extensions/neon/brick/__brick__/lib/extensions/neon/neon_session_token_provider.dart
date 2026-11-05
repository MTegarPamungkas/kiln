import 'neon_auth_gateway.dart';
import 'neon_token_provider.dart';

/// Prefers the signed-in user's JWT, falling back to an anonymous or static
/// token when the user is signed out. This keeps `remote_database` authorized
/// across both states.
final class NeonSessionTokenProvider implements NeonTokenProvider {
  NeonSessionTokenProvider({required this.auth, this.fallback});

  final NeonAuthGateway auth;
  final NeonTokenProvider? fallback;

  @override
  Future<String?> token() async =>
      await auth.accessJwt() ?? await fallback?.token();
}
