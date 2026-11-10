import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/theme/color_schemes.dart';

void main() {
  const seed = Color(0xFF0F766E);

  test('builds light and dark schemes from one seed', () {
    final light = ColorSchemes.light(seed);
    final dark = ColorSchemes.dark(seed);

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.primary, isNot(dark.primary));
    expect(light.surface, isNot(dark.surface));
  });

  test('different seeds produce different palettes', () {
    final teal = ColorSchemes.light(seed);
    final blue = ColorSchemes.light(const Color(0xFF1D4ED8));

    expect(blue.primary, isNot(teal.primary));
  });

  test('high contrast variants keep the brightness', () {
    expect(ColorSchemes.lightHighContrast(seed).brightness, Brightness.light);
    expect(ColorSchemes.darkHighContrast(seed).brightness, Brightness.dark);
    expect(
      ColorSchemes.lightHighContrast(seed).primary,
      isNot(ColorSchemes.light(seed).primary),
    );
  });

  test('explicit contrast level matches the high contrast helper', () {
    expect(
      ColorSchemes.fromSeed(seed, Brightness.dark, contrastLevel: 1).primary,
      ColorSchemes.darkHighContrast(seed).primary,
    );
  });
}
