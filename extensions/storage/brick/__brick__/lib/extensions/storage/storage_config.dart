/// Configuration for the platform key-value store.
final class StorageConfig {
  const StorageConfig({
    required this.prefix,
    this.schemaVersion = 1,
  });

  static const defaults = StorageConfig(prefix: '{{app_name}}.');

  final String prefix;
  final int schemaVersion;
}
