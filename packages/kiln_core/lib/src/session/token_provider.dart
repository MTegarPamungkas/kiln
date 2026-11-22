/// Supplies the access token used by authenticated HTTP requests.
abstract interface class TokenProvider {
  /// Returns an access token, or null when no session can supply one.
  ///
  /// [deadline] is the deadline of the request that needs the token. A provider
  /// that refreshes over HTTP should pass it to the refresh request so the
  /// caller's whole budget stays shared; providers backed by an SDK may only
  /// honour it where the SDK supports cancellation.
  Future<String?> accessToken({bool forceRefresh = false, DateTime? deadline});

  Future<void> clear();
}
