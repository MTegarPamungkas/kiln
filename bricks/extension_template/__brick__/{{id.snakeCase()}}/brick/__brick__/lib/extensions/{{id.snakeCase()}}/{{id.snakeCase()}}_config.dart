/// Typed configuration for the {{name}} extension.
class {{id.pascalCase()}}Config {
  const {{id.pascalCase()}}Config({required this.enabled});

  static const defaults = {{id.pascalCase()}}Config(enabled: true);

  final bool enabled;
}
