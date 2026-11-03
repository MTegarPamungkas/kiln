# Kiln registry

Registry lokal yang dihasilkan dari folder `extensions/` oleh:

```bash
dart run tool/registry.dart
```

Isinya:

- `index.json` — daftar extension, versi, checksum, dan compatibility.
- `archives/<id>-<version>.tgz` — arsip extension yang sudah dipaketkan.

## Memakai registry

```bash
kiln config --registry="$(pwd)/registry"
kiln store search http
kiln store install http_retry
kiln upgrade
```

Untuk registry HTTP, arahkan `--registry` atau `kiln config --registry` ke URL
yang menyajikan `index.json` dan folder `archives/`. Mirror opsional dapat
dikonfigurasi dengan `kiln config --mirror=<url>`.

`kiln ext publish --registry=<folder>` menambahkan satu versi baru ke registry
lokal lalu memperbarui `index.json`. Publish ke URL HTTP tidak didukung; dorong
folder registry dengan Git atau mekanisme rilis lain.

## Verifikasi

Setiap arsip diverifikasi memakai SHA-256 dari index sebelum dipasang. Arsip
dengan path traversal ditolak. Extension community atau yang memiliki hook
meminta konfirmasi sebelum dipasang.

## Pemeriksaan CI

```bash
dart run tool/registry.dart --check
```

Perintah ini membandingkan index dan arsip hasil generate dengan isi folder
`registry/`.
