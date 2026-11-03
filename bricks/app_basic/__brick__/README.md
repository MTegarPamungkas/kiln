# {{name}}

Aplikasi Flutter yang dibuat dengan Kiln.

## Menjalankan

```bash
flutter pub get
flutter run
```

## Struktur

- `lib/app/` — kerangka aplikasi, registry, dan shell MaterialApp. `KilnApp`
  meneruskan lifecycle Flutter ke `LifecycleController` dan mengakhiri sesi
  saat `expiresAt` terlewati. Daftarkan `AppHome` di registry untuk mengganti
  halaman utama tanpa mengubah shell.
- `lib/core/` — theme, seam `CoreCopy` yang diisi extension l10n, dan
  penanganan error.
- `lib/l10n/` — file ARB; semua teks aplikasi berasal dari sini.
- `lib/extensions/` — kode extension yang dipasang lewat `kiln add`.
- `kiln.yaml` — konfigurasi proyek dan jawaban prompt extension.

Tambahkan extension tanpa mengedit kerangka aplikasi:

```bash
kiln add dio
kiln add bloc
kiln doctor
```
