# theme

Extension tema untuk aplikasi Kiln. Ia mengganti `AppThemeConfig` bawaan dengan
`ThemeData` terang dan gelap yang dibangun dari satu warna seed, menambahkan
token desain, warna semantik, dan kontrol mode terang atau gelap.

- `BrandTheme` merakit `ThemeData` dari `ColorScheme.fromSeed`, skala teks, dan
  tema komponen.
- `ThemeModeController` menyimpan `ThemeMode` hidup lewat `modeListenable`
  sehingga `AppShell` ikut membangun ulang.
- `ThemeModeStore` menyimpan pilihan mode lewat kontrak `Storage` bila
  extension storage terpasang.
- `AppSpacing`, `AppRadius`, dan `SemanticColors` tersedia sebagai
  `ThemeExtension`; akses cepat lewat `context.spacing`, `context.radii`, dan
  `context.semantic`.
- `ThemeModeSwitcher` menampilkan pilihan Sistem, Terang, dan Gelap.

## Pasang

```bash
kiln add theme
```

Prompt yang ditanyakan: `seed_color`, `font_family`, `corner_radius`, dan
`density`.

## Pakai

```dart
final controller = registry.read<ThemeModeController>();

await controller.setMode(ThemeMode.dark);
```

```dart
final padding = context.spacing.md;
final warning = context.semantic.warning;
final primary = context.colors.primary;
```

```dart
ThemeModeSwitcher(controller: registry.read<ThemeModeController>())
```

Dokumentasi lengkap ada di [docs/theme.md](docs/theme.md),
[docs/design-tokens.md](docs/design-tokens.md), dan
[docs/rebranding.md](docs/rebranding.md).
