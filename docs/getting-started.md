# Memulai Kiln

## Prasyarat

- Flutter 3.47 atau lebih baru
- Dart 3.13 atau lebih baru
- Git (opsional untuk proyek hasil generate)

## Setup repo

```bash
git clone <repo-kiln>
cd kiln
flutter pub get
dart analyze
```

Semua test:

```bash
cd packages/kiln_core && dart test
cd ../kiln_testing && flutter test
cd ../kiln_extension_sdk && dart test
cd ../kiln_cli && dart test
cd ../../extensions/dio && dart test
```

## Membuat aplikasi

Jalankan CLI dari source. `--core-path` membuat proyek memakai `kiln_core` dan
`kiln_testing` dari workspace, bukan dari pub.dev:

```bash
dart run packages/kiln_cli/bin/kiln.dart create my_app \
  --org com.example \
  --core-path "$PWD/packages/kiln_core" \
  --with dio \
  --answer base_url=https://api.example.com \
  --yes
```

`kiln create` selalu memasang extension `l10n`, sehingga seluruh teks shell
berasal dari ARB dan template tidak menyimpan string aplikasi hardcoded.
`l10n` juga otomatis menambah `flutter: generate: true` dan menjalankan
gen-l10n saat `pub get`.

Tanpa `--with`, proyek tetap bisa dibuat lalu extension lain ditambahkan:

```bash
cd my_app
dart run ../packages/kiln_cli/bin/kiln.dart add dio \
  --answer base_url=https://api.example.com
```

Perintah lain:

```bash
kiln list
kiln doctor
kiln graph
kiln remove dio --yes
```

## Struktur proyek hasil generate

```text
my_app/
├─ lib/
│  ├─ main.dart
│  ├─ app/            # KilnApp, RegistryScope, AppShell, error screen
│  ├─ core/           # theme, l10n, global error handler
│  ├─ extensions/     # kode extension + extensions.g.dart
│  └─ ...
├─ test/
├─ kiln.yaml
├─ kiln.lock.yaml
└─ .kiln/             # jurnal dan backup, di-ignore Git
```

`lib/extensions/extensions.g.dart` adalah satu-satunya file aplikasi yang
dimiliki Kiln. Jangan diedit manual; `kiln doctor --fix` akan
mensinkronkannya.

## Menulis extension

```bash
kiln ext new hello --name "Hello extension" --provides hello
kiln ext validate extensions/hello
kiln ext test extensions/hello
kiln ext pack extensions/hello
```

Baca [extensions/writing-an-extension.md](extensions/writing-an-extension.md)
dan [extension-manifest.md](extension-manifest.md).

## Katalog bawaan

Fase 2 saat ini menyediakan:

- `bloc` dan `riverpod` untuk state management (exclusive).
- `dio` untuk HTTP client dan pipeline.
- `http_retry` dan `http_cache` untuk ketahanan dan cache HTTP.
- `storage`, `secure_storage`, dan `local_db` untuk key-value, rahasia, dan
  database offline-first.
- `connectivity`, `permission`, `notifications`, dan `image_picker` untuk
  status jaringan, izin, notifikasi lokal, dan pemilihan gambar.
- `rest_auth`, `appwrite`, `firebase`, dan `supabase` untuk autentikasi,
  remote database, dan file storage; `social_login` dan `biometric` untuk
  jalur masuk sosial, app lock, dan penyimpanan terlindungi.
- `go_router`, `deep_link`, `theme`, dan `l10n` untuk navigasi, tautan masuk,
  tema, serta lokalisasi berbasis file ARB.
- `env`, `flavors`, `logger`, dan `analytics` untuk konfigurasi build-time,
  entry point per flavor, logging, dan analitik dengan consent.

```bash
kiln create state_app --state bloc
kiln add http_retry
kiln add http_cache
kiln add connectivity permission notifications image_picker
```

## Registry

```bash
kiln config --registry="$(pwd)/registry"
kiln store search logger
kiln store install logger --yes
kiln upgrade --yes
```

Publish satu extension ke registry lokal:

```bash
kiln ext publish extensions/logger --registry="$(pwd)/registry"
```

`tool/registry.dart` membangun ulang `registry/index.json` dan seluruh arsip
dari folder `extensions/`.

## Batasan saat ini

- Publish langsung ke registry HTTP belum aktif; publish ke folder lokal.
- `kiln_lints` menunggu `custom_lint` mendukung analyzer 14.
