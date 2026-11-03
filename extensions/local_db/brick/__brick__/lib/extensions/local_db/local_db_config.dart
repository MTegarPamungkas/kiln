/// Configuration for the local Sembast database.
final class LocalDbConfig {
  const LocalDbConfig({
    this.databaseName = '{{app_name}}.db',
    this.schemaVersion = 1,
    this.path,
  });

  static const defaults = LocalDbConfig();

  final String databaseName;
  final int schemaVersion;
  final String? path;
}
