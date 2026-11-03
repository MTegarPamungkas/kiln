import 'package:kiln_core/kiln_core.dart';

/// Exports and restores collections as JSON-compatible maps.
final class BackupExport {
  const BackupExport();

  Future<Map<String, Object?>> export({
    required LocalDatabase database,
    required Iterable<String> collections,
  }) async {
    final data = <String, Object?>{};
    for (final collection in collections) {
      data[collection] = <Map<String, Object?>>[
        for (final record in await database.query(collection))
          <String, Object?>{'key': record.key, 'data': record.data},
      ];
    }
    return <String, Object?>{'version': 1, 'collections': data};
  }

  Future<void> import({
    required LocalDatabase database,
    required Map<String, Object?> backup,
  }) async {
    final collections = backup['collections'];
    if (collections is! Map) {
      return;
    }
    for (final entry in collections.entries) {
      final collection = '${entry.key}';
      final records = entry.value;
      if (records is! Iterable) {
        continue;
      }
      for (final record in records) {
        if (record is! Map) {
          continue;
        }
        final key = '${record['key'] ?? ''}';
        final data = record['data'];
        if (key.isEmpty || data is! Map) {
          continue;
        }
        await database.put(
          collection,
          key,
          Map<String, Object?>.from(data),
        );
      }
    }
  }
}
