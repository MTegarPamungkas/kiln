# Theme

Extension ini mendaftarkan `AppThemeConfig` bertipe ke Registry, sehingga
`AppShell` memakai `BrandTheme` alih-alih tema bawaan. `AppThemeConfig`
menyimpan `ThemeData` terang dan gelap serta `modeListenable`; saat controller
mengubah mode, `AppShell` membangun ulang `MaterialApp` tanpa restart.

## Prompt

| Prompt | Arti | Bawaan |
| --- | --- | --- |
| `seed_color` | Warna seed Material, `#RRGGBB` atau `#AARRGGBB` | `#0F766E` |
| `font_family` | Font untuk skala teks; kosong memakai font platform | kosong |
| `corner_radius` | Radius dasar komponen dalam piksel logis | `14` |
| `density` | `comfortable` atau `compact` | `comfortable` |

Nilai prompt dirender ke `ThemeConfig.defaults`. Warna yang tidak valid jatuh
kembali ke teal Kiln agar aplikasi tetap bisa dibangun.

## Mode terang dan gelap

`ThemeModeController` memiliki `ValueNotifier<ThemeMode>` yang diekspos sebagai
`modeListenable`. Modul mendaftarkan controller, lalu memanggil `load()` pada
tahap `ready` untuk memulihkan pilihan terakhir.

```dart
final controller = registry.read<ThemeModeController>();

await controller.setMode(ThemeMode.light);
```

Bila extension `storage` terpasang, `ThemeModeStore` menulis kunci `theme.mode`
lewat `Storage`. Tanpa storage, penyimpanan dilewati dan pergantian mode tetap
bekerja selama proses aplikasi berjalan.

`ThemeModeSwitcher` siap dipasang di halaman pengaturan:

```dart
ThemeModeSwitcher(controller: controller)
```

## Kontras tinggi

`ColorSchemes` menyediakan `lightHighContrast` dan `darkHighContrast` dengan
`contrastLevel: 1`. `BrandTheme.lightHighContrast` dan
`BrandTheme.darkHighContrast` memakai skema tersebut bila aplikasi perlu
menyediakan opsi aksesibilitas.

## Status bar

`SystemUiStyle.fromTheme(theme)` menghasilkan gaya status bar dan navigation
bar sesuai brightness. Panggil `SystemUiStyle.apply(theme)` dari widget root
bila aplikasi mengelola system UI sendiri.

## Daftar isi

- [Token desain](design-tokens.md)
- [Rebranding](rebranding.md)
