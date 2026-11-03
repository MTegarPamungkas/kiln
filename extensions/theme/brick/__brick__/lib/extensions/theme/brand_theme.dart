import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'component_themes.dart';
import 'design_tokens.dart';
import 'semantic_colors.dart';
import 'text_styles.dart';
import 'theme_config.dart';

/// Assembles the light and dark [ThemeData] for a [ThemeConfig].
final class BrandTheme {
  BrandTheme(this.config)
    : light = create(config, Brightness.light),
      dark = create(config, Brightness.dark);

  /// Settings shared by both brightnesses.
  final ThemeConfig config;

  /// Theme used when the app runs in light mode.
  final ThemeData light;

  /// Theme used when the app runs in dark mode.
  final ThemeData dark;

  /// High-contrast light theme.
  ThemeData get lightHighContrast =>
      create(config, Brightness.light, highContrast: true);

  /// High-contrast dark theme.
  ThemeData get darkHighContrast =>
      create(config, Brightness.dark, highContrast: true);

  /// Builds one theme from the seed, typography, and component themes.
  static ThemeData create(
    ThemeConfig config,
    Brightness brightness, {
    bool highContrast = false,
  }) {
    final colors = highContrast
        ? ColorSchemes.highContrast(config.seedColor, brightness)
        : ColorSchemes.fromSeed(config.seedColor, brightness);
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      visualDensity: config.visualDensity,
    );
    final textTheme = AppTextStyles.build(
      base: base.textTheme,
      colors: colors,
      fontFamily: config.fontFamily,
    );
    final components = ComponentThemes.build(
      config: config,
      colors: colors,
      textTheme: textTheme,
    );
    final spacing = config.isCompact
        ? AppSpacing.compact
        : AppSpacing.comfortable;

    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,
      appBarTheme: components.appBar,
      filledButtonTheme: FilledButtonThemeData(style: components.filledButton),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: components.elevatedButton,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: components.outlinedButton,
      ),
      textButtonTheme: TextButtonThemeData(style: components.textButton),
      inputDecorationTheme: components.input,
      cardTheme: components.card,
      dialogTheme: components.dialog,
      snackBarTheme: components.snackBar,
      navigationBarTheme: components.navigationBar,
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant.withValues(alpha: 0.6),
        space: 1,
      ),
      extensions: <ThemeExtension<dynamic>>[
        spacing,
        AppRadius.fromCornerRadius(config.cornerRadius),
        SemanticColors.forBrightness(brightness),
      ],
    );
  }
}
