import 'dart:convert';

import 'package:kiln_core/kiln_core.dart';

/// Last successful remote-config snapshot.
final class RemoteConfigSnapshot {
  const RemoteConfigSnapshot({required this.values, required this.fetchedAt});

  final Map<String, Object?> values;

  /// When the values were fetched from the endpoint.
  final DateTime fetchedAt;
}

/// Persists the last-known-good snapshot so an offline start can still gate
/// features on the last values the server sent.
abstract interface class RemoteConfigCache {
  Future<void> save(RemoteConfigSnapshot snapshot);

  /// The stored snapshot, or null when nothing valid was stored.
  Future<RemoteConfigSnapshot?> load();

  Future<void> clear();
}

/// [RemoteConfigCache] over a [Storage] bucket.
///
/// A malformed snapshot is dropped instead of failing startup, and the key is
/// namespaced by the storage extension like every other value.
final class StorageRemoteConfigCache implements RemoteConfigCache {
  StorageRemoteConfigCache({
    required this.storage,
    this.key = 'remote_config.snapshot',
  });

  final Storage storage;
  final String key;

  @override
  Future<void> save(RemoteConfigSnapshot snapshot) {
    return storage.write(
      key,
      jsonEncode(<String, Object?>{
        'fetchedAt': snapshot.fetchedAt.toUtc().toIso8601String(),
        'values': snapshot.values,
      }),
    );
  }

  @override
  Future<RemoteConfigSnapshot?> load() async {
    final raw = await storage.read(key);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final fetchedAt = DateTime.tryParse('${decoded['fetchedAt']}');
        final values = decoded['values'];
        if (fetchedAt != null && values is Map) {
          return RemoteConfigSnapshot(
            values: <String, Object?>{
              for (final entry in values.entries) '${entry.key}': entry.value,
            },
            fetchedAt: fetchedAt.toUtc(),
          );
        }
      }
    } on FormatException {
      // Fall through and drop the unusable snapshot.
    }
    await clear();
    return null;
  }

  @override
  Future<void> clear() => storage.delete(key);
}
