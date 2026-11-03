# theme

Theme extension for Kiln apps. It replaces the default `AppThemeConfig` with
light and dark `ThemeData` built from a single seed color, and adds design
tokens, semantic colors, and light or dark mode control.

- `BrandTheme` assembles `ThemeData` from `ColorScheme.fromSeed`, the text scale, and
  component themes.
- `ThemeModeController` keeps the live `ThemeMode` through `modeListenable`
  so that `AppShell` rebuilds as well.
- `ThemeModeStore` persists the mode choice through the `Storage` contract when
  the storage extension is installed.
- `AppSpacing`, `AppRadius`, and `SemanticColors` are available as
  `ThemeExtension`s; quick access through `context.spacing`, `context.radii`, and
  `context.semantic`.
- The application renders its own appearance controls and calls the controller.

## Install

```bash
kiln add theme
```

Prompts requested: `seed_color`, `font_family`, `corner_radius`, and
`density`.

## Usage

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
SegmentedButton<ThemeMode>(
  segments: const <ButtonSegment<ThemeMode>>[
    ButtonSegment(value: ThemeMode.system, label: Text('System')),
    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
  ],
  selected: <ThemeMode>{registry.read<ThemeModeController>().mode},
  onSelectionChanged: (Set<ThemeMode> selection) =>
      registry.read<ThemeModeController>().setMode(selection.first),
)
```

Full documentation is in [docs/theme.md](docs/theme.md),
[docs/design-tokens.md](docs/design-tokens.md), and
[docs/rebranding.md](docs/rebranding.md).

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
