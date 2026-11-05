import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/theme/theme_config.dart';

void main() {
  test('defaults match the install prompts', () {
    final config = ThemeConfig.defaults;

    expect(config.seedColor, const Color(0xFF0F766E));
    expect(config.fontFamily, isNull);
    expect(config.cornerRadius, 14);
    expect(config.density, ThemeDensity.comfortable);
    expect(config.isCompact, isFalse);
    expect(config.visualDensity, VisualDensity.standard);
  });

  test('parses hex seeds with and without a leading hash', () {
    expect(themeSeedColor('#1D4ED8'), const Color(0xFF1D4ED8));
    expect(themeSeedColor('1d4ed8'), const Color(0xFF1D4ED8));
    expect(themeSeedColor('  #0f766e  '), const Color(0xFF0F766E));
    expect(themeSeedColor('#800F766E'), const Color(0x800F766E));
  });

  test('falls back to Kiln teal for invalid seeds', () {
    expect(themeSeedColor('teal'), const Color(0xFF0F766E));
    expect(themeSeedColor('#12345'), const Color(0xFF0F766E));
    expect(themeSeedColor(''), const Color(0xFF0F766E));
  });

  test('compact density reports compact visuals', () {
    const config = ThemeConfig(
      seedColor: Color(0xFF1D4ED8),
      fontFamily: 'Inter',
      cornerRadius: 8,
      density: ThemeDensity.compact,
    );

    expect(config.isCompact, isTrue);
    expect(config.visualDensity, VisualDensity.compact);
    expect(config.fontFamily, 'Inter');
  });

  test('copyWith replaces only the given values', () {
    final copy = ThemeConfig.defaults.copyWith(
      seedColor: const Color(0xFF1D4ED8),
      cornerRadius: 20,
    );

    expect(copy.seedColor, const Color(0xFF1D4ED8));
    expect(copy.cornerRadius, 20);
    expect(copy.fontFamily, isNull);
    expect(copy.density, ThemeDensity.comfortable);
  });
}
