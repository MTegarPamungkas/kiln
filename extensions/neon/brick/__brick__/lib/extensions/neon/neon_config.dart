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
    this.schema = 'public',
    this.watchInterval = const Duration(seconds: 5),
  });

  /// Values rendered from the extension prompts.
  static const NeonConfig defaults = NeonConfig(
    dataApiUrl: '{{{data_api_url}}}',
    apiKey: '{{{api_key}}}',
    schema: '{{{schema}}}',
  );

  static final RegExp _schemaPattern = RegExp(r'^[a-z_][a-z0-9_]*$');

  /// Base URL of the Neon Data API (PostgREST), e.g. `https://pg.neon.tech`.
  final String dataApiUrl;

  /// Bearer token sent with every request. Use a Neon Auth JWT, not a service key.
  final String apiKey;

  /// Postgres schema exposed through the Data API.
  final String schema;

  /// How often [RemoteDatabase.watch] polls for a changed row.
  final Duration watchInterval;

  /// Whether the Data API URL uses plain `http` (self-hosted/local dev).
  bool get isInsecureTransport =>
      Uri.tryParse(dataApiUrl)?.isScheme('http') ?? false;

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
    if (apiKey.trim().isEmpty) {
      return const Failure(
        code: FailureCode.configurationMissing,
        message: 'The Neon Data API bearer token is not set.',
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
    String? schema,
    Duration? watchInterval,
  }) {
    return NeonConfig(
      dataApiUrl: dataApiUrl ?? this.dataApiUrl,
      apiKey: apiKey ?? this.apiKey,
      schema: schema ?? this.schema,
      watchInterval: watchInterval ?? this.watchInterval,
    );
  }
}
