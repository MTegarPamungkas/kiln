# Rebranding

Rebranding tidak menyentuh fitur. Semua warna turunan berasal dari satu seed,
dan tipografi, radius, serta kepadatan berasal dari prompt lain di
`ThemeConfig`.

## Mengganti warna seed

Pasang ulang extension dengan seed baru:

```bash
kiln add theme
```

Saat prompt muncul, isi `seed_color` dengan warna merek, misalnya `#1D4ED8`.
`ColorScheme.fromSeed` menurunkan primary, secondary, tertiary, container,
surface, dan pasangan `on*` untuk mode terang dan gelap. Tema komponen dan
`SemanticColors` mengikuti palet yang sama.

Bila seed diubah manual, perbarui `ThemeConfig.defaults` di
`lib/extensions/theme/theme_config.dart`, lalu jalankan ulang aplikasi. Jangan
mengubah warna komponen satu per satu; perubahan seed sudah cukup.

## Mengganti font

Isi prompt `font_family` dengan nama family yang tersedia di aplikasi. Daftarkan
font tersebut lewat `pubspec.yaml` aplikasi atau `google_fonts` sesuai
kebutuhan. Nilai kosong mempertahankan font platform.

## Mengubah radius dan kepadatan

`corner_radius` mengubah `AppRadius` dan bentuk tombol, input, kartu, dialog,
serta `SnackBar`. `density` mengubah `VisualDensity`, skala `AppSpacing`, tinggi
`NavigationBar`, dan padding komponen.

## Yang tidak perlu diubah

- Kode fitur tetap memakai `context.colors`, `context.spacing`, dan
  `context.semantic`.
- `AppThemeConfig` tetap didaftarkan oleh `ThemeModule`; jangan mendaftarkan
  `AppThemeConfig` kedua.
- `ThemeModeSwitcher` dan `ThemeModeController` tidak bergantung pada nilai
  prompt, jadi rebranding tidak mengubah perilaku mode.
