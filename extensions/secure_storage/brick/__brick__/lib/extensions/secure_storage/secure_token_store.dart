import 'package:kiln_core/kiln_core.dart';

/// Stores access and refresh tokens and exposes them as a [TokenProvider].
final class SecureTokenStore implements TokenProvider {
  SecureTokenStore({
    required this.storage,
    this.accessTokenKey = 'access_token',
    this.refreshTokenKey = 'refresh_token',
  });

  final SecureStorage storage;
  final String accessTokenKey;
  final String refreshTokenKey;

  Future<void> save({
    required String accessToken,
    String? refreshToken,
  }) async {
    await storage.write(accessTokenKey, accessToken);
    if (refreshToken != null) {
      await storage.write(refreshTokenKey, refreshToken);
    }
  }

  Future<String?> refreshToken() => storage.read(refreshTokenKey);

  @override
  Future<String?> accessToken({bool forceRefresh = false}) {
    return storage.read(accessTokenKey);
  }

  @override
  Future<void> clear() async {
    await storage.delete(accessTokenKey);
    await storage.delete(refreshTokenKey);
  }
}
