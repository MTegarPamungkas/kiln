# Contributing

## Setup

```bash
flutter pub get
dart analyze
```

## Test

```bash
cd packages/kiln_core && dart test
cd ../kiln_testing && flutter test
cd ../kiln_extension_sdk && dart test
cd ../kiln_cli && dart test
cd ../../extensions/dio && dart test
```

Setelah mengubah brick atau manifest extension:

```bash
dart run tool/bundle.dart
dart run tool/bundle.dart --check
```

## Aturan desain

- Kode aplikasi dan extension hanya bergantung pada kontrak `kiln_core`.
- Extension bergantung pada capability, bukan id extension lain.
- Akses layanan lewat Registry; tidak ada fasad statis atau global registry.
- Kontrak melempar `Failure`; `Result<T>` adalah helper untuk kode fitur.
- Semua perubahan instalasi lewat transaksi dengan jurnal dan rollback.
- Jangan mengedit file milik pengguna. `remove` hanya menghapus file yang
  hash-nya masih cocok.
- Extension tidak mengimpor extension lain; gunakan slot.
- Komentar kode dalam bahasa Inggris; teks UI mengikuti bahasa produk.

## Dependency

Gunakan versi terbaru yang bisa di-resolve toolchain. Jalankan
`flutter pub outdated`; jangan menurunkan versi tanpa alasan. Dua pin yang
didokumentasikan di `README.md` (`test` dan `kiln_lints`) mengikuti Flutter SDK
dan `custom_lint`.

## Pull request

- Jelaskan alasan perubahan, bukan hanya isinya.
- Sertakan test untuk perilaku baru atau bug yang diperbaiki.
- Pastikan `dart analyze` bersih, semua suite hijau, dan bundle check lulus.
- Jangan campur refactor besar dengan perubahan perilaku.
