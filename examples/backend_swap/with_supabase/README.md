# with_supabase

Aplikasi Flutter yang dibuat dengan Kiln.

## Menjalankan

```bash
flutter pub get
flutter run
```

## Struktur

- `lib/app/` — kerangka aplikasi, registry, dan shell MaterialApp.
- `lib/core/` — theme, lokalisasi, dan penanganan error.
- `lib/extensions/` — kode extension yang dipasang lewat `kiln add`.
- `kiln.yaml` — konfigurasi proyek dan jawaban prompt extension.

Tambahkan extension tanpa mengedit kerangka aplikasi:

```bash
kiln add dio
kiln add bloc
kiln doctor
```
