# Changelog

## 0.1.0

- Registry client implementation: `RegistryConfig` (HTTP(S), `file:`, local
  path, mirror, ref) and `RegistryClient` (fetch index, mirror fallback,
  download archives with SHA-256 verification, optional cache).
- `index.json` models matching `schemas/registry-index.schema.json`:
  `RegistryIndex`, `RegistryExtension`, `RegistryVersion`, parse/encode, local
  search through `SearchIndex`.
- `VersionResolver` based on `pub_semver` to select a version compatible with
  `kiln_core`/Dart and to skip installed or prerelease versions.
- `ChecksumVerifier` rejects archives whose SHA-256 does not match
  (`store.checksum_mismatch`).
- `TrustPolicy` for the official/verified/community tiers and hook
  confirmation.
- Deterministic `ArchivePacker` (`.tar.gz`, POSIX paths, fixed timestamps) and
  `ArchiveUnpacker` that rejects zip-slip, absolute paths, drive letters,
  symlinks, and hard links (`store.unsafe_archive`).
- `LocalCache` and `OfflineMode` for an offline index/archives with cache
  fallback when the network fails.
- `Publisher` for manifest validation, duplicate version rejection, archive
  writing, `index.json` updates, and automatic `latest`.
- `KilnStoreException` with `code`, `message`, `suggestion`, and `details`.
- Unit tests for every module, including index fixtures, valid archives, and
  zip-slip archives.
