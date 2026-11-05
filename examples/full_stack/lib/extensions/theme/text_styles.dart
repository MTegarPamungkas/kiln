import 'package:flutter/material.dart';

/// Builds the typography scale applied to every generated theme.
abstract final class AppTextStyles {
  /// Applies the brand font and weights to the Material [base] text theme.
  static TextTheme build({
    required TextTheme base,
    required ColorScheme colors,
    String? fontFamily,
  }) {
    final themed = base.apply(
      fontFamily: fontFamily,
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );
    return themed.copyWith(
      displayLarge: themed.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
      ),
      displayMedium: themed.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.25,
      ),
      displaySmall: themed.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineMedium: themed.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: themed.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: themed.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: themed.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: themed.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}
