/// Social identity providers supported by the contract.
enum SocialProvider { google, apple }

/// Credential returned by a social provider.
final class SocialCredential {
  const SocialCredential({
    required this.provider,
    required this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
  });

  final SocialProvider provider;
  final String idToken;
  final String? accessToken;
  final String? email;
  final String? displayName;
}

/// Signs the user in with a social provider.
abstract interface class SocialAuth {
  Future<SocialCredential?> signIn(SocialProvider provider);

  Future<void> signOut();
}

/// High-level social sign-in service supplied by the `social_login` extension.
abstract interface class SocialLogin implements SocialAuth {}
