# Changelog

## 0.1.0

- Implementasi klien registry: `RegistryConfig` (HTTP(S), `file:`, path lokal,
  mirror, ref) dan `RegistryClient` (fetch index, fallback mirror, unduh arsip
  dengan verifikasi SHA-256, cache opsional).
- Model `index.json` sesuai `schemas/registry-index.schema.json`:
  `RegistryIndex`, `RegistryExtension`, `RegistryVersion`, parse/encode, pencarian
  lokal melalui `SearchIndex`.
- `VersionResolver` berbasis `pub_semver` untuk memilih versi yang cocok dengan
  `kiln_core`/Dart dan mengabaikan versi terpasang atau prerelease.
- `ChecksumVerifier` menolak arsip dengan SHA-256 tidak cocok
  (`store.checksum_mismatch`).
- `TrustPolicy` untuk tier official/verified/community dan konfirmasi hook.
- `ArchivePacker` deterministik (`.tar.gz`, path POSIX, timestamp tetap) dan
  `ArchiveUnpacker` yang menolak zip-slip, path absolut, drive letter, symlink,
  dan hard link (`store.unsafe_archive`).
- `LocalCache` dan `OfflineMode` untuk index/arsip offline dengan fallback cache
  saat jaringan gagal.
- `Publisher` untuk validasi manifest, penolakan versi duplikat, penulisan arsip,
  pembaruan `index.json`, dan `latest` otomatis.
- `KilnStoreException` dengan `code`, `message`, `suggestion`, dan `details`.
- Test unit untuk seluruh modul, termasuk fixture index, arsip valid, dan arsip
  zip-slip.
