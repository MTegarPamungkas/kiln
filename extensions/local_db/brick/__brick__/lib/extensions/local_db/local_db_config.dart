/// Configuration for the local Sembast database.
final class LocalDbConfig {
  const LocalDbConfig({
    this.databaseName = '{{app_name}}.db',
    this.schemaVersion = 1,
    this.path,
    this.recoverIncompleteImports = true,
  });

  static const defaults = LocalDbConfig();

  final String databaseName;
  final int schemaVersion;
  final String? path;

  /// Whether startup rolls back a backup import that a previous process died
  /// inside. Disable it to keep local_db from opening the database during
  /// `ready` and to call `BackupExport.recover` yourself instead.
  final bool recoverIncompleteImports;
}
