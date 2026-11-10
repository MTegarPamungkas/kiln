import 'checksum_verifier.dart';
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
    _validateCache();
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

  /// Returns bytes verified against the exact metadata selected by the caller.
  /// No second online index lookup may silently replace that selection.
  /// Offline use additionally requires matching metadata cached for this registry.
  Future<List<int>> archive(String id, RegistryVersion version) async {
    _validateCache();
    if (offline) {
      final trusted = (await _cachedIndex()).find(id)?.findVersion(version.version);
      if (trusted == null ||
          trusted.sha256.toLowerCase() != version.sha256.toLowerCase() ||
          trusted.url != version.url) {
        throw const KilnStoreException(
          'No matching selected version metadata is cached for this registry.',
          code: 'store.offline_missing',
        );
      }
    }
    final cached = await cache.readArchive(id, version.version);
    if (cached != null) {
      try {
        const ChecksumVerifier().verify(cached, version.sha256);
        return cached;
      } on KilnStoreException {
        if (offline) rethrow;
        // Refresh only from the selected URL and SHA, never a new index lookup.
      }
    }
    if (offline) {
      throw KilnStoreException(
        'Archive $id ${version.version} is not available in the offline cache.',
        code: 'store.offline_missing',
        suggestion: 'Install it once while online to cache the archive.',
      );
    }
    final bytes = await client.downloadArchive(
      id,
      version,
      indexUri: client.config.indexUri,
    );
    const ChecksumVerifier().verify(bytes, version.sha256);
    cache.writeArchive(id, version.version, bytes);
    return bytes;
  }

  void _validateCache() {
    if (cache.registryIdentity != client.config.identity) {
      throw const KilnStoreException(
        'Cache belongs to a different registry.', code: 'store.invalid_config',
      );
    }
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
