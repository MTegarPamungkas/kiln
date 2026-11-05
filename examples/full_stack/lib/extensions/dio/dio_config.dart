/// Typed configuration for the dio HTTP client.
class DioConfig {
  const DioConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.defaultHeaders = const <String, String>{},
  });

  static const defaults = DioConfig(
    baseUrl: 'https://api.example.com',
    connectTimeout: Duration(seconds: 15),
  );

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Map<String, String> defaultHeaders;
}
