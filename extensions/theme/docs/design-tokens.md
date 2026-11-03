# Design tokens

Design tokens are available as `ThemeExtension`s, so their values follow the
active theme and can be lerped when `AnimatedTheme` switches modes.

## Spacing

`AppSpacing` contains `xs`, `sm`, `md`, `lg`, `xl`, and `xxl`. The `comfortable`
scale has the values 4, 8, 16, 24, 32, and 48. The `compact` scale has the values
3, 6, 12, 18, 24, and 36.

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

`AppRadius` derives `sm`, `md`, `lg`, and `xl` from the `corner_radius` prompt.
The `md` value equals the base radius; `sm` is 0.6 times, `lg` 1.4 times, and
`xl` 2 times the base radius. `pill` is used for fully rounded shapes.

```dart
final radius = context.radii;

Card(
  shape: RoundedRectangleBorder(borderRadius: radius.lgBorder),
  child: const SizedBox(),
);
```

The same radius is used by the `AppBar`, button, input, `Card`, `Dialog`,
`SnackBar`, and `NavigationBar` themes, so a single prompt keeps everything
consistent.

## Semantic colors

`SemanticColors` provides `success`, `warning`, and `info` along with their
`onSuccess`, `onWarning`, and `onInfo` counterparts. The light and dark palettes
are chosen automatically from the brightness, and every pair meets WCAG AA
contrast.

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

## Typography

`AppTextStyles.build` applies the `fontFamily` from the prompt, the text colors
from the scheme, and consistent weights: `display*` 800, `headline*` 700,
`title*` and `labelLarge` 600. The sizes follow the Material 3 scale so they stay
readable on small screens.
