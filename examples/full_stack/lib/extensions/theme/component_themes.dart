import 'package:flutter/material.dart';

import 'theme_config.dart';

/// Component themes assembled from the brand configuration and palette.
final class ComponentThemes {
  const ComponentThemes({
    required this.appBar,
    required this.filledButton,
    required this.elevatedButton,
    required this.outlinedButton,
    required this.textButton,
    required this.input,
    required this.card,
    required this.dialog,
    required this.snackBar,
    required this.navigationBar,
  });

  /// Builds every component theme for [colors] and [textTheme].
  static ComponentThemes build({
    required ThemeConfig config,
    required ColorScheme colors,
    required TextTheme textTheme,
  }) {
    final compact = config.isCompact;
    final radius = BorderRadius.circular(config.cornerRadius);
    final buttonShape = RoundedRectangleBorder(borderRadius: radius);
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: compact ? 16 : 20,
      vertical: compact ? 12 : 16,
    );
    final buttonTextStyle = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final snackRadius = config.cornerRadius - 4 < 0
        ? 0.0
        : config.cornerRadius - 4;
    final dialogRadius = config.cornerRadius + 6;

    return ComponentThemes(
      appBar: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      filledButton: FilledButton.styleFrom(
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonTextStyle,
      ),
      elevatedButton: ElevatedButton.styleFrom(
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonTextStyle,
        elevation: 0,
      ),
      outlinedButton: OutlinedButton.styleFrom(
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonTextStyle,
        side: BorderSide(color: colors.outline),
      ),
      textButton: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        shape: buttonShape,
        textStyle: buttonTextStyle,
      ),
      input: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 10 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.error, width: 1.6),
        ),
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        labelStyle: TextStyle(color: colors.onSurfaceVariant),
      ),
      card: CardThemeData(
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      dialog: DialogThemeData(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      snackBar: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        actionTextColor: colors.inversePrimary,
        elevation: 2,
        insetPadding: EdgeInsets.all(compact ? 12 : 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(snackRadius),
        ),
      ),
      navigationBar: NavigationBarThemeData(
        height: compact ? 60 : 68,
        backgroundColor: colors.surfaceContainerLow,
        elevation: 0,
        indicatorColor: colors.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  final AppBarTheme appBar;
  final ButtonStyle filledButton;
  final ButtonStyle elevatedButton;
  final ButtonStyle outlinedButton;
  final ButtonStyle textButton;
  final InputDecorationTheme input;
  final CardThemeData card;
  final DialogThemeData dialog;
  final SnackBarThemeData snackBar;
  final NavigationBarThemeData navigationBar;
}
