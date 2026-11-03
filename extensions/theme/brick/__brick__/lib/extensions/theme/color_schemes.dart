import 'package:flutter/material.dart';

/// Builds Material color schemes from the brand seed.
abstract final class ColorSchemes {
  /// Scheme for [brightness] with an explicit WCAG [contrastLevel].
  static ColorScheme fromSeed(
    Color seed,
    Brightness brightness, {
    double contrastLevel = 0.0,
  }) {
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      contrastLevel: contrastLevel,
    );
  }

  /// Standard light scheme.
  static ColorScheme light(Color seed) => fromSeed(seed, Brightness.light);

  /// Standard dark scheme.
  static ColorScheme dark(Color seed) => fromSeed(seed, Brightness.dark);

  /// High-contrast scheme for [brightness].
  static ColorScheme highContrast(Color seed, Brightness brightness) =>
      fromSeed(seed, brightness, contrastLevel: 1.0);

  /// High-contrast light scheme.
  static ColorScheme lightHighContrast(Color seed) =>
      highContrast(seed, Brightness.light);

  /// High-contrast dark scheme.
  static ColorScheme darkHighContrast(Color seed) =>
      highContrast(seed, Brightness.dark);
}
