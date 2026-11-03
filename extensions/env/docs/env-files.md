# Env files

Extension ini mengirim tiga file contoh:

- `env/development.example.json`
- `env/staging.example.json`
- `env/production.example.json`

Salin file yang diperlukan menjadi nama tanpa `.example`:

```bash
cp env/development.example.json env/development.json
```

File asli di-ignore oleh `env/.gitignore`. Jangan commit nilai lingkungan nyata.

Pilih file lewat `--dart-define-from-file`:

```bash
flutter run --dart-define-from-file=env/development.json
```

Flutter CLI juga menerima daftar file yang dipisahkan koma pada versi terbaru.
Nilai di file tetap menjadi konstanta saat build; mengubah file memerlukan
build ulang.
