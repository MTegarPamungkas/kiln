/// Build-time values compiled into the application.
///
/// Each key is a separate `String.fromEnvironment` constant because the
/// constructor argument must be a compile-time constant.
abstract final class BuildEnvValues {
  static const apiBaseUrl = String.fromEnvironment(
    'api_base_url',
    defaultValue: 'https://api.example.com',
  );
  static const apiKey = String.fromEnvironment('api_key');
  static const featureFlags = String.fromEnvironment('feature_flags');
  static const enableDebugTools = String.fromEnvironment(
    'enable_debug_tools',
    defaultValue: 'true',
  );

  static const values = <String, String>{
    'api_base_url': apiBaseUrl,
    'api_key': apiKey,
    'feature_flags': featureFlags,
    'enable_debug_tools': enableDebugTools,
  };
}
