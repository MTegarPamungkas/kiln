import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'semantic_colors.dart';

/// Short accessors for the theme extensions and Material palette.
extension ThemeContextX on BuildContext {
  /// The active Material theme.
  ThemeData get theme => Theme.of(this);

  /// Active Material color scheme.
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Active Material typography.
  TextTheme get textStyles => Theme.of(this).textTheme;

  /// Spacing scale, with the comfortable scale as a fallback.
  AppSpacing get spacing =>
      Theme.of(this).extension<AppSpacing>() ?? AppSpacing.comfortable;

  /// Corner radius scale, derived from the base radius when unavailable.
  AppRadius get radii =>
      Theme.of(this).extension<AppRadius>() ??
      AppRadius.fromCornerRadius(14);

  /// Success, warning, and info colors for the active brightness.
  SemanticColors get semantic =>
      Theme.of(this).extension<SemanticColors>() ??
      SemanticColors.forBrightness(Theme.of(this).brightness);
}
