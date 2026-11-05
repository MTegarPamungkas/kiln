import 'package:kiln_core/kiln_core.dart';

typedef LocalDbMigration = Future<void> Function(LocalDatabase database);

/// Applies schema migrations in order and records the version.
final class SchemaMigrator {
  SchemaMigrator({
    required this.database,
    required this.targetVersion,
    this.migrations = const <LocalDbMigration>[],
    this.metadataCollection = '_schema',
    this.versionKey = 'version',
  });

  final LocalDatabase database;
  final int targetVersion;
  final List<LocalDbMigration> migrations;
  final String metadataCollection;
  final String versionKey;

  Future<int> run() async {
    final metadata = await database.get(metadataCollection, versionKey);
    final current = int.tryParse('${metadata?['value'] ?? ''}') ?? 0;
    if (current >= targetVersion) {
      return current;
    }
    for (var version = current; version < targetVersion; version++) {
      final migration = version < migrations.length
          ? migrations[version]
          : null;
      if (migration != null) {
        await migration(database);
      }
    }
    await database.put(
      metadataCollection,
      versionKey,
      <String, Object?>{'value': targetVersion},
    );
    return targetVersion;
  }
}
