# Theme

This extension registers a typed `AppThemeConfig` in the Registry, so `AppShell`
uses `BrandTheme` instead of the default theme. `AppThemeConfig` holds the light
and dark `ThemeData` plus `modeListenable`; when the controller changes the mode,
`AppShell` rebuilds `MaterialApp` without a restart.

## Prompts

| Prompt | Meaning | Default |
| --- | --- | --- |
| `seed_color` | Material seed color, `#RRGGBB` or `#AARRGGBB` | `#0F766E` |
| `font_family` | Font for the text scale; empty uses the platform font | empty |
| `corner_radius` | Base component radius in logical pixels | `14` |
| `density` | `comfortable` or `compact` | `comfortable` |

The prompt values are rendered to `ThemeConfig.defaults`. An invalid color falls
back to Kiln teal so the app can still be built.

## Light and dark mode

`ThemeModeController` owns a `ValueNotifier<ThemeMode>` that is exposed as
`modeListenable`. The module registers the controller, then calls `load()` during
the `ready` stage to restore the last choice.

```dart
final controller = registry.read<ThemeModeController>();

await controller.setMode(ThemeMode.light);
```

If the `storage` extension is installed, `ThemeModeStore` writes the
`theme.mode` key through `Storage`. Without storage, persistence is skipped and
mode switching still works while the app process is running.

`ThemeModeSwitcher` is ready to be placed on a settings page:

```dart
ThemeModeSwitcher(controller: controller)
```

## High contrast

`ColorSchemes` provides `lightHighContrast` and `darkHighContrast` with
`contrastLevel: 1`. `BrandTheme.lightHighContrast` and
`BrandTheme.darkHighContrast` use those schemes if the app needs to offer an
accessibility option.

## Status bar

`SystemUiStyle.fromTheme(theme)` produces a status bar and navigation bar style
that matches the brightness. Call `SystemUiStyle.apply(theme)` from the root
widget if the app manages system UI itself.

## Table of contents

- [Design tokens](design-tokens.md)
- [Rebranding](rebranding.md)
