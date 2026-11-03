/// Supplies the access token used by authenticated HTTP requests.
abstract interface class TokenProvider {
  Future<String?> accessToken({bool forceRefresh = false});

  Future<void> clear();
}
