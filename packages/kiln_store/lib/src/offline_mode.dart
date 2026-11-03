import 'kiln_store_exception.dart';
import 'local_cache.dart';
import 'registry_client.dart';
import 'registry_index.dart';

/// Uses the local cache when the registry is unreachable or offline mode is on.
final class OfflineMode {
  const OfflineMode({
    required this.client,
    required this.cache,
    this.offline = false,
  });

  final RegistryClient client;
  final LocalCache cache;

  /// When true, the network is never touched.
  final bool offline;

  /// Returns the registry index.
  ///
  /// Offline returns the cached index or throws `store.offline_missing`.
  /// Online fetches and caches a fresh index, falling back to the cached copy
  /// when the network fails.
  Future<RegistryIndex> index() async {
    if (offline) {
      return _cachedIndex();
    }
    try {
      final index = await client.fetchIndex();
      cache.writeIndex(index);
      return index;
    } on Exception {
      final cached = await cache.readIndex();
      if (cached == null) {
        rethrow;
      }
      return cached;
    }
  }

  /// Returns the archive for [id] at [version], cache first.
  ///
  /// When missing, resolves the registry entry, downloads and verifies it, and
  /// stores it in the cache before returning it.
  Future<List<int>> archive(String id, String version) async {
    final cached = await cache.readArchive(id, version);
    if (cached != null) {
      return cached;
    }
    final index = await this.index();
    final extension = index.find(id);
    if (extension == null) {
      throw KilnStoreException(
        'Extension "$id" is not present in the registry.',
        code: 'store.extension_not_found',
      );
    }
    final entry = extension.findVersion(version);
    if (entry == null) {
      throw KilnStoreException(
        'Version "$version" of extension "$id" is not present in the registry.',
        code: 'store.version_not_found',
      );
    }
    if (offline) {
      throw KilnStoreException(
        'Archive $id $version is not available in the offline cache.',
        code: 'store.offline_missing',
        suggestion: 'Install it once while online to cache the archive.',
      );
    }
    final bytes = await client.downloadArchive(
      id,
      entry,
      indexUri: client.config.indexUri,
    );
    cache.writeArchive(id, version, bytes);
    return bytes;
  }

  Future<RegistryIndex> _cachedIndex() async {
    final cached = await cache.readIndex();
    if (cached == null) {
      throw KilnStoreException(
        'Offline mode is enabled but no registry index is cached.',
        code: 'store.offline_missing',
        suggestion:
            'Run a command while online, or disable offline mode to fetch the '
            'registry.',
      );
    }
    return cached;
  }
}
