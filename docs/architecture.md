# Arsitektur Kiln

Kiln adalah monorepo Dart yang menghasilkan aplikasi Flutter dan memeliharanya
lewat extension. Aplikasi hasil generate hanya mengenal kontrak di
`kiln_core`; extension tidak saling mengimpor.

## Package

| Package | Tanggung jawab |
| --- | --- |
| `kiln_core` | Kontrak, `Failure`, `Result`, Registry, bootstrap, slot, sesi, privasi |
| `kiln_extension_sdk` | Manifest, resolver, renderer Mason, installer transaksional, migrasi |
| `kiln_cli` | Perintah `kiln`, prompt, laporan, bundle extension |
| `kiln_testing` | Fake per kontrak, contract suite, harness widget |
| `kiln_store` | Registry, checksum, trust, publish (fase registry) |
| `kiln_lints` | Aturan lint custom untuk kontrak, plugin, dan file generated |

## Runtime aplikasi

1. `main.dart` menjalankan `KilnBootstrap.run(modules: kilnModules())`.
2. Bootstrap menyusun module dari capability `requires`/`provides`.
3. Setiap module mendaftarkan layanan ke `Registry`.
4. `KilnApp` menyediakan Registry lewat `RegistryScope`.
5. `AppShell` membaca seam `AppThemeConfig`, `AppLocalizationsConfig`,
   `RouterConfig`, dan slot `app.wrappers`.
6. Fitur membaca kontrak (`RegistryScope.read<HttpClient>()`), bukan
   implementasi.

Tidak ada fasad statis atau global registry. Semua akses layanan melewati
Registry yang dioper eksplisit.

## Model extension

Extension terdiri dari:

- `extension.yaml` — manifest: kapabilitas, prompt, slot, dependency, patch
  native, compatibility.
- `brick/` — template Mason yang dirender ke proyek pengguna.
- `test/` — test manifest, render, dan analyze tingkat extension.
- `README.md`, `CHANGELOG.md`, `docs/` — dokumentasi extension.

Extension hanya berkomunikasi lewat kapabilitas dan slot. `http_retry`
bergantung pada `http_client`/`http_pipeline`, bukan pada id `dio`.

## Pemasangan transaksional

`kiln add` menjalankan pipeline berikut:

1. Baca `kiln.yaml` dan `kiln.lock.yaml`.
2. Resolver memilih provider capability, mendeteksi konflik exclusive,
   slot yang tidak dibuka, dan siklus dependency.
3. Render brick ke folder sementara.
4. Terapkan collision policy terhadap hash kepemilikan di lockfile.
5. Hitung patch native dan perubahan `pubspec.yaml`/`extensions.g.dart`.
6. Tulis semua perubahan dalam satu `Transaction` dengan jurnal, backup, dan
   rollback.
7. Verifikasi `pub get` dan `analyze` bila diaktifkan.

`kiln remove` hanya menghapus file yang hash-nya masih sama dengan lockfile.
File yang diedit pengguna dilewati kecuali `--force`.

## Error model

Kontrak melempar `Failure` dengan `FailureCode` stabil. Feature code dapat
mengubahnya menjadi `Result<T>` dengan `Result.guard`. `kiln_core` juga memuat
`Result` sebagai helper, bukan kontrak kedua.

## Dependency

Semua dependency memakai caret ke rilis terbaru yang bisa di-resolve toolchain
saat ini. Dua pengecualian didokumentasikan di `README.md`: `test` mengikuti pin
`test_api` milik Flutter, dan `kiln_lints` mengikuti `custom_lint_builder`.

Lihat [folder-structure.md](folder-structure.md) untuk target struktur lengkap
dan [roadmap.md](roadmap.md) untuk urutan fase.
