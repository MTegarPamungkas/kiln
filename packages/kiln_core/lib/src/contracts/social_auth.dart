/// Social identity providers supported by the contract.
enum SocialProvider { google, apple }

/// Which layer issued the [SocialCredential.idToken].
enum SocialTokenAudience {
  /// The identity token was issued by Google or Apple for a backend exchange.
  provider,

  /// The token belongs to the backend session that the adapter established.
  /// Never forward it to another backend as a provider identity token.
  backend,
}

/// Credential returned by a social provider or a backend adapter.
///
/// Native provider acquisition (`social_login`) sets [audience] to
/// [SocialTokenAudience.provider], fills [idToken] with the provider identity
/// token, and supplies [rawNonce] and [authorizationCode] when the backend
/// exchange needs them. A backend adapter that already created its own session
/// sets [audience] to [SocialTokenAudience.backend] and exposes that session in
/// [backendSessionToken]; a provider token must never be placed there.
final class SocialCredential {
  const SocialCredential({
    required this.provider,
    required this.idToken,
    this.accessToken,
    this.audience = SocialTokenAudience.provider,
    this.backendSessionToken,
    this.rawNonce,
    this.authorizationCode,
    this.email,
    this.displayName,
  });

  final SocialProvider provider;

  /// Provider identity token, or the backend token when [audience] is
  /// [SocialTokenAudience.backend].
  final String idToken;

  /// Provider access token. Backend session tokens belong in
  /// [backendSessionToken] instead.
  final String? accessToken;

  final SocialTokenAudience audience;

  /// Session token created by the backend adapter, when it established one.
  final String? backendSessionToken;

  /// Unhashed nonce that matches the hashed nonce in [idToken].
  ///
  /// A backend that exchanges the identity token must verify this value.
  final String? rawNonce;

  /// Provider authorization code for a server-side code exchange.
  final String? authorizationCode;

  final String? email;
  final String? displayName;

  SocialCredential copyWith({
    SocialProvider? provider,
    String? idToken,
    String? accessToken,
    SocialTokenAudience? audience,
    String? backendSessionToken,
    String? rawNonce,
    String? authorizationCode,
    String? email,
    String? displayName,
  }) {
    return SocialCredential(
      provider: provider ?? this.provider,
      idToken: idToken ?? this.idToken,
      accessToken: accessToken ?? this.accessToken,
      audience: audience ?? this.audience,
      backendSessionToken: backendSessionToken ?? this.backendSessionToken,
      rawNonce: rawNonce ?? this.rawNonce,
      authorizationCode: authorizationCode ?? this.authorizationCode,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  String toString() =>
      'SocialCredential(provider: ${provider.name}, '
      'audience: ${audience.name}, idToken: '
      '${idToken.isEmpty ? '[empty]' : '[set]'})';
}

/// Signs the user in with a social provider.
abstract interface class SocialAuth {
  Future<SocialCredential?> signIn(SocialProvider provider);

  Future<void> signOut();
}

/// High-level social sign-in service supplied by the `social_login` extension.
abstract interface class SocialLogin implements SocialAuth {}
