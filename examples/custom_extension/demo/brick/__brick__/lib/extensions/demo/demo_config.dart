/// Typed configuration for the Demo extension extension.
class DemoConfig {
  const DemoConfig({required this.enabled});

  static const defaults = DemoConfig(enabled: true);

  final bool enabled;
}
