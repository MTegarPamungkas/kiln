# Token desain

Token desain tersedia sebagai `ThemeExtension`, jadi nilainya ikut tema aktif
dan dapat di-lerp saat `AnimatedTheme` berganti mode.

## Spasi

`AppSpacing` berisi `xs`, `sm`, `md`, `lg`, `xl`, dan `xxl`. Skala
`comfortable` bernilai 4, 8, 16, 24, 32, dan 48. Skala `compact` bernilai 3, 6,
12, 18, 24, dan 36.

```dart
final spacing = context.spacing;

Padding(
  padding: spacing.pagePadding,
  child: Column(
    children: <Widget>[
      Text('Judul'),
      spacing.sectionGap,
      Text('Isi'),
    ],
  ),
);
```

## Radius

`AppRadius` menurunkan `sm`, `md`, `lg`, dan `xl` dari prompt
`corner_radius`. Nilai `md` sama dengan radius dasar; `sm` adalah 0,6 kali,
`lg` 1,4 kali, dan `xl` 2 kali radius dasar. `pill` dipakai untuk bentuk bulat
penuh.

```dart
final radius = context.radii;

Card(
  shape: RoundedRectangleBorder(borderRadius: radius.lgBorder),
  child: const SizedBox(),
);
```

Radius yang sama dipakai tema `AppBar`, tombol, input, `Card`, `Dialog`,
`SnackBar`, dan `NavigationBar`, sehingga satu prompt menjaga konsistensi.

## Warna semantik

`SemanticColors` menyediakan `success`, `warning`, dan `info` beserta pasangan
`onSuccess`, `onWarning`, dan `onInfo`. Palet terang dan gelap dipilih otomatis
dari brightness dan setiap pasangan memenuhi kontras WCAG AA.

```dart
Container(
  color: context.semantic.warning,
  padding: context.spacing.cardPadding,
  child: Text(
    'Perhatian',
    style: TextStyle(color: context.semantic.onWarning),
  ),
);
```

## Tipografi

`AppTextStyles.build` menerapkan `fontFamily` dari prompt, warna teks dari
skema, dan bobot yang konsisten: `display*` 800, `headline*` 700, `title*` dan
`labelLarge` 600. Ukuran mengikuti skala Material 3 sehingga tetap terbaca
pada layar kecil.
