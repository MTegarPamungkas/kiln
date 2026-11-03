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
    baseUrl: '{{{base_url}}}',
    connectTimeout: Duration(seconds: {{connect_timeout}}),
    apiKey: String.fromEnvironment('KILN_API_KEY'),
    apiKeyHeader: '{{{api_key_header}}}',
    apiKeyQueryParameter: '{{{api_key_query}}}',
    apiKeyPrefix: '{{{api_key_prefix}}}',
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
}
