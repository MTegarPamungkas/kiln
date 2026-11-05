import 'package:flutter/material.dart';

final RegExp _rgbPattern = RegExp(r'^[0-9a-fA-F]{6}$');
final RegExp _argbPattern = RegExp(r'^[0-9a-fA-F]{8}$');

/// Parses a `#RRGGBB` or `#AARRGGBB` value into a [Color].
///
/// The installer writes the prompt value as a string so a typo cannot break
/// the generated project. Input that is not a hex color falls back to Kiln
/// teal.
Color themeSeedColor(
  String value, {
  Color fallback = const Color(0xFF0F766E),
}) {
  final hex = value.trim().replaceFirst(RegExp('^#'), '');
  final isRgb = _rgbPattern.hasMatch(hex);
  final isArgb = _argbPattern.hasMatch(hex);
  if (!isRgb && !isArgb) {
    return fallback;
  }
  final parsed = int.parse(hex, radix: 16);
  return Color(isRgb ? 0xFF000000 | parsed : parsed);
}

/// Normalizes the font prompt; an empty value means the platform font.
String? themeFontFamily(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Layout density selected during installation.
enum ThemeDensity {
  comfortable,
  compact;

  /// Whether the compact scale should be used.
  bool get isCompact => this == ThemeDensity.compact;
}

/// Theme settings rendered from the install prompts.
final class ThemeConfig {
  const ThemeConfig({
    required this.seedColor,
    this.fontFamily,
    this.cornerRadius = 14,
    this.density = ThemeDensity.comfortable,
  });

  /// Values the Kiln installer writes into the application.
  static final ThemeConfig defaults = ThemeConfig(
    seedColor: themeSeedColor('#0F766E'),
    fontFamily: themeFontFamily(''),
    cornerRadius: 14,
    density: ThemeDensity.comfortable,
  );

  /// Seed used by `ColorScheme.fromSeed` for both brightnesses.
  final Color seedColor;

  /// Optional font family applied to the text theme.
  final String? fontFamily;

  /// Base corner radius shared by component themes and [AppRadius].
  final double cornerRadius;

  /// Spacing and component density.
  final ThemeDensity density;

  /// Whether the compact density was selected.
  bool get isCompact => density.isCompact;

  /// Material visual density that matches [density].
  VisualDensity get visualDensity =>
      isCompact ? VisualDensity.compact : VisualDensity.standard;

  ThemeConfig copyWith({
    Color? seedColor,
    String? fontFamily,
    double? cornerRadius,
    ThemeDensity? density,
  }) {
    return ThemeConfig(
      seedColor: seedColor ?? this.seedColor,
      fontFamily: fontFamily ?? this.fontFamily,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      density: density ?? this.density,
    );
  }
}
