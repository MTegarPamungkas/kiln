/// Connectivity settings from the install prompts.
final class ConnectivityConfig {
  const ConnectivityConfig({
    this.probeUrl,
    this.probeInterval = const Duration(seconds: 30),
    this.probeTimeout = const Duration(seconds: 5),
    this.debounceWindow = const Duration(milliseconds: 500),
  });

  static const defaults = ConnectivityConfig(
    {{#probe_url}}probeUrl: '{{{probe_url}}}',
    {{/probe_url}}probeInterval: Duration(seconds: {{probe_interval}}),
    probeTimeout: Duration(seconds: {{probe_timeout}}),
    debounceWindow: Duration(milliseconds: {{debounce_ms}}),
  );

  final String? probeUrl;
  final Duration probeInterval;
  final Duration probeTimeout;
  final Duration debounceWindow;
}
