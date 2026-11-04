import 'package:kiln_core/kiln_core.dart';

/// Typed configuration for the Supabase extension.
///
/// `url`, `anonKey`, and `schema` come from the `extension.yaml` prompts; the
/// remaining values use safe defaults and can be changed in one place. A local
/// or self-hosted stack may use a plain `http` URL (see
/// `docs/supabase-setup.md`); `supabase_flutter` accepts it, and Android needs
/// a cleartext rule for the development host.
final class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    this.schema = 'public',
    this.storageBucket = 'public',
    this.authRedirectUrl = 'kiln-auth://auth-callback',
    this.usePkce = true,
    this.autoRefreshToken = true,
    this.persistSession = true,
    this.detectSessionInUri = false,
    this.signedUrlLifetime = const Duration(hours: 1),
    this.authTimeout = const Duration(minutes: 5),
  });

  /// Values rendered from the extension prompts.
  static const SupabaseConfig defaults = SupabaseConfig(
    url: '{{{url}}}',
    anonKey: '{{{anon_key}}}',
    schema: '{{{schema}}}',
  );

  static final RegExp _schemaPattern = RegExp(r'^[a-z_][a-z0-9_]*$');

  /// Project URL, for example `https://abcdefgh.supabase.co`.
  final String url;

  /// Anon (publishable) key. Never use the service role key on the client.
  final String anonKey;

  /// PostgREST schema used by `RemoteDatabase`.
  final String schema;

  /// Default bucket used by `FileStorage`.
  final String storageBucket;

  /// Callback URL for email confirmation, password reset, and OAuth.
  final String authRedirectUrl;

  /// Uses the PKCE flow for authorization code exchange.
  final bool usePkce;

  /// Refreshes the access token automatically while the app runs.
  final bool autoRefreshToken;

  /// Persists the session in device local storage.
  final bool persistSession;

  /// Lets the SDK read the session from an incoming URI. It is off by default
  /// because callbacks are handled by [SupabaseLinkHandler] through the
  /// `DeepLinks` contract.
  final bool detectSessionInUri;

  /// Lifetime of the signed link returned by `FileStorage.url`.
  final Duration signedUrlLifetime;

  /// How long to wait for a session after OAuth opens in the browser.
  final Duration authTimeout;

  /// Callback URL as a [Uri], or null when it cannot be parsed.
  Uri? get redirectUri => Uri.tryParse(authRedirectUrl);

  /// Whether the project URL uses plain `http` instead of `https`.
  bool get isInsecureTransport => Uri.tryParse(url)?.isScheme('http') ?? false;

  /// Validates the configuration before the client is created.
  ///
  /// Returns null when valid, or a [Failure] with a message safe to show to
  /// developers. The anon key never appears in the message.
  Failure? validate() {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.host.isEmpty ||
        !(uri.isScheme('http') || uri.isScheme('https'))) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message:
            'The Supabase URL must be a complete http or https address.',
        kind: FailureKind.configuration,
      );
    }
    if (anonKey.trim().isEmpty) {
      return const Failure(
        code: FailureCode.configurationMissing,
        message: 'The Supabase anon key is not set.',
        kind: FailureKind.configuration,
      );
    }
    if (!_schemaPattern.hasMatch(schema)) {
      return Failure(
        code: FailureCode.configurationInvalid,
        message: 'Schema "$schema" is not a valid PostgREST identifier.',
        kind: FailureKind.configuration,
      );
    }
    final redirect = Uri.tryParse(authRedirectUrl);
    if (redirect == null || !redirect.hasScheme) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message:
            'authRedirectUrl must be a URI with a scheme, for example kiln-auth://auth-callback.',
        kind: FailureKind.configuration,
      );
    }
    if (signedUrlLifetime <= Duration.zero) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'The signed URL lifetime must be greater than zero.',
        kind: FailureKind.configuration,
      );
    }
    return null;
  }

  SupabaseConfig copyWith({
    String? url,
    String? anonKey,
    String? schema,
    String? storageBucket,
    String? authRedirectUrl,
    bool? usePkce,
    bool? autoRefreshToken,
    bool? persistSession,
    bool? detectSessionInUri,
    Duration? signedUrlLifetime,
    Duration? authTimeout,
  }) {
    return SupabaseConfig(
      url: url ?? this.url,
      anonKey: anonKey ?? this.anonKey,
      schema: schema ?? this.schema,
      storageBucket: storageBucket ?? this.storageBucket,
      authRedirectUrl: authRedirectUrl ?? this.authRedirectUrl,
      usePkce: usePkce ?? this.usePkce,
      autoRefreshToken: autoRefreshToken ?? this.autoRefreshToken,
      persistSession: persistSession ?? this.persistSession,
      detectSessionInUri: detectSessionInUri ?? this.detectSessionInUri,
      signedUrlLifetime: signedUrlLifetime ?? this.signedUrlLifetime,
      authTimeout: authTimeout ?? this.authTimeout,
    );
  }
}
