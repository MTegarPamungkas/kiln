import 'package:kiln_core/kiln_core.dart';

typedef StorageMigration = Future<void> Function(Storage storage);

/// Runs storage schema migrations in order.
final class StorageMigrator {
  StorageMigrator({
    required this.storage,
    required this.targetVersion,
    this.migrations = const <StorageMigration>[],
    this.versionKey = 'schema_version',
  });

  final Storage storage;
  final int targetVersion;
  final List<StorageMigration> migrations;
  final String versionKey;

  Future<int> run() async {
    final raw = await storage.read(versionKey);
    final current = int.tryParse(raw ?? '') ?? 0;
    if (current >= targetVersion) {
      return current;
    }
    for (var version = current; version < targetVersion; version++) {
      final migration = version < migrations.length
          ? migrations[version]
          : null;
      if (migration != null) {
        await migration(storage);
      }
    }
    await storage.write(versionKey, '$targetVersion');
    return targetVersion;
  }
}
