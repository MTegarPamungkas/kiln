# kiln_store

Klien registry, verifikasi arsip, trust policy, dan publisher extension untuk
Kiln. Package ini tidak bergantung pada Flutter sehingga bisa dipakai CLI, tool
registry, maupun skrip rilis.

## Isi package

| Berkas | Tanggung jawab |
| --- | --- |
| `registry_config.dart` | URL utama, mirror, ref, dan normalisasi path lokal/`file:` |
| `registry_client.dart` | Mengambil `index.json` dan arsip lewat HTTP, `file:`, atau folder lokal |
| `registry_index.dart` | Model `index.json` (`RegistryIndex`, `RegistryExtension`, `RegistryVersion`) |
| `version_resolver.dart` | Memilih versi tertinggi yang cocok dengan `kiln_core` (dan Dart) |
| `search_index.dart` | Pencarian lokal berdasarkan id, nama, deskripsi, dan kategori |
| `checksum_verifier.dart` | Verifikasi SHA-256 arsip sebelum dipasang |
| `trust_policy.dart` | Level official/verified/community dan konfirmasi hook |
| `archive_packer.dart` | Membuat `.tar.gz` deterministik dari folder extension |
| `archive_unpacker.dart` | Mengekstrak arsip dan menolak path traversal serta link |
| `publisher.dart` | Validasi manifest lalu menulis arsip dan `index.json` |
| `local_cache.dart` | Cache index dan arsip di disk |
| `offline_mode.dart` | Memakai cache saat offline atau jaringan gagal |
| `kiln_store_exception.dart` | Error dengan `code`, `message`, `suggestion`, `details` |

## Konfigurasi registry

```dart
final config = RegistryConfig(
  url: 'https://raw.githubusercontent.com/contoh/registry/main',
  mirror: 'https://mirror.contoh.dev/kiln',
);

config.indexUri;        // .../index.json
config.mirrorIndexUri;  // .../index.json atau null
config.resolve('archives/dio-0.2.0.tgz');
```

`url` dan `mirror` menerima URL HTTP(S), URI `file:`, atau path filesystem
(termasuk `C:\registry` di Windows). Path lokal dinormalisasi menjadi `file:`
saat URI dibutuhkan. Placeholder `{ref}` diganti dengan `ref` ketika path
diselesaikan, sehingga satu konfigurasi bisa mengikuti branch atau tag.

`RegistryConfig.fromMap`/`toJson` dipakai oleh konfigurasi CLI.

## Mengambil index dan arsip

```dart
final cache = LocalCache(Directory(cacheDir));
final client = RegistryClient(config: config, cache: cache);
final index = await client.fetchIndex();

final extension = index.find('dio')!;
final version = extension.findVersion('0.2.0')!;
final bytes = await client.downloadArchive(
  extension.id,
  version,
  indexUri: config.indexUri,
);
```

`fetchIndex` memakai registry utama lebih dulu lalu mirror sebagai fallback;
`useMirror: true` membalik urutannya. Respons non-200, file yang hilang, dan
kegagalan jaringan menjadi `KilnStoreException` dengan kode
`store.fetch_failed`. `downloadArchive` selalu memverifikasi SHA-256 dan menulis
ke cache bila tersedia.

## Memilih versi dan mencari extension

```dart
final selected = const VersionResolver().resolve(
  extension,
  kilnVersion: Version.parse('0.1.0'),
  installedVersion: '0.1.0',
  dartVersion: Version.parse('3.9.0'),
);

final matches = SearchIndex(index).search('http');
```

Resolver hanya menerima versi yang lolos constraint `compatibility['kiln']`
(dan `compatibility['dart']` bila diberikan), melewati prerelease kecuali
`allowPrerelease: true`, dan tidak pernah memilih versi yang sama atau lebih
rendah dari versi terpasang. Constraint yang tidak ada dianggap kompatibel;
constraint rusak dilewati.

## Trust policy

```dart
final decision = const TrustPolicy().evaluate(manifest, hasHooks: true);
if (!decision.allowed) { /* tolak */ }
if (decision.requiresConfirmation) { /* minta konfirmasi */ }
```

Official selalu diizinkan. Verified dan community mengikuti `allowed`
(bawaan: semua tier). Community meminta konfirmasi bila `confirmCommunity`, dan
extension dengan hook meminta konfirmasi bila `confirmHooks`.

## Arsip

```dart
final bytes = const ArchivePacker().pack(extensionRoot);
const ArchiveUnpacker().extract(bytes, target);

final sha256 = sha256Hex(bytes);
const ChecksumVerifier().verify(bytes, expectedSha256);
```

Packer menulis path relatif POSIX, mengurutkan entri, memakai timestamp dan mode
tetap, serta melewati `.dart_tool`, `.git`, `build`, `.kiln`, dan arsip `.tgz`
yang dihasilkan. Karena itu isi yang sama menghasilkan byte yang sama, yang
dibutuhkan oleh `tool/registry.dart --check`.

Unpacker memvalidasi seluruh entri sebelum menulis apa pun, lalu menolak path
absolut, drive letter, segmen kosong, `..`, backslash, symlink, hard link, dan
special file dengan kode `store.unsafe_archive`. Arsip yang bukan `.tar.gz`
ditolak dengan `store.invalid_archive`.

## Cache dan mode offline

```dart
final mode = OfflineMode(client: client, cache: cache, offline: true);
final index = await mode.index();
final bytes = await mode.archive('dio', '0.2.0');
```

Mode offline tidak pernah menyentuh jaringan: index dibaca dari cache atau
melempar `store.offline_missing`, dan arsip yang belum tercache juga melempar
`store.offline_missing` (setelah memastikan id/versi ada di index). Dalam mode
online, kegagalan mengambil index jatuh ke cache bila tersedia.

Layout cache:

```text
<cache>/index.json
<cache>/archives/<id>-<version>.tgz
```

## Publish

```dart
final result = await Publisher().publish(
  extensionRoot: extension,
  registryRoot: registry,
  archiveBaseUrl: Uri.parse('https://cdn.contoh.dev/kiln'), // opsional
);
```

Publisher memvalidasi `extension.yaml` dengan `ManifestValidator`, menolak versi
duplikat kecuali `force: true`, menulis
`registry/archives/<id>-<version>.tgz`, menghitung SHA-256, lalu memperbarui
`registry/index.json`. Extension lain dan versi lain dipertahankan; extension
diurutkan berdasarkan id dan versi secara menaik. `latest` selalu versi
tertinggi. Tanpa `archiveBaseUrl`, URL arsip disimpan relatif sebagai
`archives/<id>-<version>.tgz`.

## Menjalankan test

```bash
cd packages/kiln_store
dart test
dart analyze
```

Fixture berada di `test/fixtures/registry/`: `index.json`, `valid.tgz`, dan
`zip-slip.tgz` (arsip berbahaya untuk menguji penolakan path traversal).
