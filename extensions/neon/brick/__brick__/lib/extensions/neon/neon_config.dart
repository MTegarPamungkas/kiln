import 'package:kiln_core/kiln_core.dart';

/// Typed configuration for the Neon extension.
///
/// `dataApiUrl`, `apiKey`, and `schema` come from the `extension.yaml` prompts.
/// The Data API is a PostgREST-compatible HTTP endpoint in front of Lakebase
/// Postgres; the bearer token plus RLS are what protect it, so the key here must
/// be a client-safe token (a Neon Auth JWT), never a service-role secret.
final class NeonConfig {
  const NeonConfig({
    required this.dataApiUrl,
    required this.apiKey,
    this.authUrl,
    this.schema = 'public',
    this.watchInterval = const Duration(seconds: 5),
  });

  /// Values rendered from the extension prompts.
  static const NeonConfig defaults = NeonConfig(
    dataApiUrl: '{{{data_api_url}}}',
    apiKey: '{{{api_key}}}',
    authUrl: '{{{auth_url}}}',
    schema: '{{{schema}}}',
  );

  static final RegExp _schemaPattern = RegExp(r'^[a-z_][a-z0-9_]*$');

  /// Base URL of the Neon Data API (PostgREST), e.g. `https://pg.neon.tech`.
  final String dataApiUrl;

  /// Bearer token sent with every request. Use a Neon Auth JWT, not a service key.
  final String apiKey;

  /// Base URL of Neon Auth (Better Auth), used to mint anonymous Data API
  /// JWTs from `{authUrl}/token/anonymous` when [apiKey] is empty.
  final String? authUrl;

  /// Postgres schema exposed through the Data API.
  final String schema;

  /// How often [RemoteDatabase.watch] polls for a changed row.
  final Duration watchInterval;

  /// Whether the Data API URL uses plain `http` (self-hosted/local dev).
  bool get isInsecureTransport =>
      Uri.tryParse(dataApiUrl)?.isScheme('http') ?? false;

  bool get _hasAuthUrl => authUrl != null && authUrl!.trim().isNotEmpty;

  /// Validates the configuration before any request is made. The key never
  /// appears in the returned message.
  Failure? validate() {
    final uri = Uri.tryParse(dataApiUrl);
    if (uri == null ||
        uri.host.isEmpty ||
        !(uri.isScheme('http') || uri.isScheme('https'))) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'The Neon Data API URL must be a complete http or https address.',
        kind: FailureKind.configuration,
      );
    }
    if (apiKey.trim().isEmpty && _hasAuthUrl) {
      final authUri = Uri.tryParse(authUrl!);
      if (authUri == null ||
          authUri.host.isEmpty ||
          !(authUri.isScheme('http') || authUri.isScheme('https'))) {
        return const Failure(
          code: FailureCode.configurationInvalid,
          message:
              'authUrl must be a complete http or https address, for example the Neon Auth base URL.',
          kind: FailureKind.configuration,
        );
      }
    }
    if (apiKey.trim().isEmpty && !_hasAuthUrl) {
      return const Failure(
        code: FailureCode.configurationMissing,
        message:
            'Provide a Data API bearer token (api_key) or a Neon Auth URL (auth_url) for anonymous access.',
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
    if (watchInterval <= Duration.zero) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'The watch interval must be greater than zero.',
        kind: FailureKind.configuration,
      );
    }
    return null;
  }

  NeonConfig copyWith({
    String? dataApiUrl,
    String? apiKey,
    String? authUrl,
    String? schema,
    Duration? watchInterval,
  }) {
    return NeonConfig(
      dataApiUrl: dataApiUrl ?? this.dataApiUrl,
      apiKey: apiKey ?? this.apiKey,
      authUrl: authUrl ?? this.authUrl,
      schema: schema ?? this.schema,
      watchInterval: watchInterval ?? this.watchInterval,
    );
  }
}
