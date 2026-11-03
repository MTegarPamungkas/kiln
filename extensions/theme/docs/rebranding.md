# Rebranding

Rebranding does not touch the features. All derived colors come from a single
seed, and typography, radius, and density come from other prompts in
`ThemeConfig`.

## Changing the seed color

Reinstall the extension with a new seed:

```bash
kiln add theme
```

When the prompt appears, fill `seed_color` with the brand color, for example
`#1D4ED8`. `ColorScheme.fromSeed` derives primary, secondary, tertiary,
container, surface, and the `on*` counterparts for light and dark mode. The
component themes and `SemanticColors` follow the same palette.

If the seed is changed manually, update `ThemeConfig.defaults` in
`lib/extensions/theme/theme_config.dart`, then restart the app. Do not change
component colors one by one; changing the seed is enough.

## Changing the font

Fill the `font_family` prompt with a family name available in the app. Register
that font through the app's `pubspec.yaml` or `google_fonts` as needed. An empty
value keeps the platform font.

## Changing the radius and density

`corner_radius` changes `AppRadius` and the shapes of buttons, inputs, cards,
dialogs, and `SnackBar`. `density` changes `VisualDensity`, the `AppSpacing`
scale, the `NavigationBar` height, and component padding.

## What does not need to change

- Feature code keeps using `context.colors`, `context.spacing`, and
  `context.semantic`.
- `AppThemeConfig` is still registered by `ThemeModule`; do not register a second
  `AppThemeConfig`.
- `ThemeModeSwitcher` and `ThemeModeController` do not depend on prompt values,
  so rebranding does not change the mode behavior.
