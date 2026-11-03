# Menambah bahasa

Ikuti langkah berikut saat menambahkan bahasa baru, misalnya Prancis (`fr`).

1. Salin `lib/l10n/app_en.arb` menjadi `lib/l10n/app_fr.arb`.
2. Ganti `@@locale` menjadi `fr` dan terjemahkan semua nilai. Jangan mengubah
   nama key atau metadata `@key`.
3. Tambahkan `fr` ke prompt `locales` di `extension.yaml` bila bahasa itu
   dipilih saat instalasi:

   ```yaml
   options:
     - id
     - en
     - fr
   ```

4. Jalankan generator:

   ```bash
   flutter gen-l10n
   ```

   `flutter pub get` juga menjalankan generator karena `flutter.generate` aktif.

5. Tambahkan nama asli bahasa di peta `_languageNames` pada
   `widgets/language_switcher.dart` bila belum ada.
6. Jalankan test:

   ```bash
   flutter test test/extensions/l10n
   ```

`l10n_coverage_test.dart` membandingkan key ARB antarbahasa. Metadata
placeholder dan plural wajib ikut disalin agar gen-l10n menghasilkan signature
yang sama.

## Catatan

- Kode bahasa mengikuti BCP-47 (`id`, `en`, `pt`, `pt_BR`). Resolusi mencocokkan
  bahasa lebih dulu, jadi `id_ID` memakai ARB `id`.
- Jangan mengubah key yang sudah dipakai aplikasi. Tambahkan key baru ke semua
  ARB.
- Folder `lib/l10n/generated` adalah hasil generate; jangan diedit manual.
