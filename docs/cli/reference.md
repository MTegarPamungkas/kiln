# Referensi CLI

## Perintah

| Perintah | Fungsi |
| --- | --- |
| `kiln create <name>` | Buat proyek dari `app_basic`; `l10n` otomatis terpasang, extension lain opsional |
| `kiln add <extension...>` | Pasang extension secara transaksional |
| `kiln remove <extension>` | Lepas extension; file yang diedit dilewati |
| `kiln repair [extension...]` | Pulihkan file generated + `extensions.g.dart`; ARB dilindungi |
| `kiln list` | Extension terpasang/tersedia |
| `kiln info <extension>` | Manifest lengkap satu extension |
| `kiln graph` | Graf requires, format `text`/`mermaid` |
| `kiln doctor` | Periksa hash, codegen, jurnal, dependency, platform |
| `kiln upgrade` | Upgrade extension dari registry (atau rencana dari katalog) |
| `kiln rollback` | Batalkan transaksi terakhir/terhenti |
| `kiln config` | Registry, mirror, mode offline |
| `kiln cache` | Lihat/bersihkan cache |
| `kiln store` | `search`, `info`, dan `install` dari registry |
| `kiln completion <shell>` | Skrip bash/zsh/fish |
| `kiln ext ...` | `new`, `validate`, `test`, `pack`, `publish` |
| `kiln version` | Versi CLI dan `kiln_core` |

## Flag umum

- `--verbose` / `--quiet`
- `--json` pada perintah yang mendukung keluaran mesin.
- `--yes` untuk mode non-interaktif.
- `--dry-run` pada `add`/`remove`/`repair`.
- `--answer nama=nilai` pada `add`/`create`/`repair`.
- `--force` pada `remove` untuk menghapus file yang sudah diedit, dan pada
  `repair` untuk menimpa ARB.
- `--core-path` pada `create` untuk memakai workspace lokal.

## Exit code

| Kode | Arti |
| --- | --- |
| 0 | Sukses |
| 64 | Argumen salah |
| 65 | Masalah proyek/manifest/prompt |
| 66 | Konflik dependency/file |
| 69 | Kegagalan jaringan |
| 70 | Verifikasi gagal |
| 71 | Kesalahan internal |

## Registry

```bash
kiln config --registry="$(pwd)/registry"
kiln store search
kiln store info connectivity
kiln store install connectivity --yes
kiln upgrade --yes
kiln ext publish extensions/connectivity --registry="$(pwd)/registry"
```

- `store install` mengunduh arsip, memverifikasi SHA-256, mengecek trust
  policy, lalu memasang lewat transaksi installer.
- `upgrade` memilih versi registry yang kompatibel, menjalankan migrasi
  terpilih, lalu mengganti extension.
- `ext publish` dan `tool/registry.dart` menulis `index.json` plus
  `archives/<id>-<version>.tgz` ke registry lokal.
- `kiln cache clean` menghapus index dan arsip yang di-cache; mode offline
  memakai cache yang tersisa.

## Batasan

- Publish ke registry HTTP belum didukung; publish ke folder lokal lalu dorong
  dengan Git atau rilis.
- Product flavor native Android/iOS tidak dibuat oleh extension flavors.
- `kiln_lints` menunggu `custom_lint` mendukung analyzer 14.
- Katalog bawaan fase 2: `analytics`, `appwrite`, `biometric`, `bloc`,
  `connectivity`, `deep_link`, `dio`, `env`, `firebase`, `flavors`,
  `go_router`, `http_cache`, `http_retry`, `image_picker`, `l10n`, `local_db`,
  `logger`, `notifications`, `permission`, `rest_auth`, `riverpod`,
  `secure_storage`, `social_login`, `storage`, `supabase`, `theme`.
