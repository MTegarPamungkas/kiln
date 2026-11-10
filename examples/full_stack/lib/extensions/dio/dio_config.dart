import 'package:kiln_core/kiln_core.dart';

/// Typed configuration for the dio HTTP client.
class DioConfig {
  const DioConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.defaultHeaders = const <String, String>{},
    this.apiKey = '',
    this.apiKeyHeader = '',
    this.apiKeyQueryParameter = '',
    this.apiKeyPrefix = '',
  });

  static const defaults = DioConfig(
    baseUrl: 'https://api.example.com',
    connectTimeout: Duration(seconds: 15),
    apiKey: String.fromEnvironment('KILN_API_KEY'),
    apiKeyHeader: '',
    apiKeyQueryParameter: '',
    apiKeyPrefix: '',
  );

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Map<String, String> defaultHeaders;

  /// Client key supplied at build time through `--dart-define=KILN_API_KEY`.
  final String apiKey;

  /// Sends [apiKey] in this header. Empty means no header.
  final String apiKeyHeader;

  /// Sends [apiKey] in this query parameter when [apiKeyHeader] is empty.
  final String apiKeyQueryParameter;

  /// Prefix for the header value, for example `Bearer `.
  final String apiKeyPrefix;

  bool get hasApiKey => apiKey.trim().isNotEmpty;

  /// Returns null when valid, or a configuration [Failure] otherwise.
  Failure? validate() {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        code: FailureCode.configurationMissing,
        message: 'The API base URL is required.',
        kind: FailureKind.configuration,
      );
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        uri.host.isEmpty ||
        !(uri.isScheme('http') || uri.isScheme('https'))) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'The API base URL must be an absolute HTTP or HTTPS URL.',
        kind: FailureKind.configuration,
      );
    }
    if (connectTimeout <= Duration.zero || receiveTimeout <= Duration.zero) {
      return const Failure(
        code: FailureCode.configurationInvalid,
        message: 'HTTP timeouts must be greater than zero.',
        kind: FailureKind.configuration,
      );
    }
    return null;
  }
}
