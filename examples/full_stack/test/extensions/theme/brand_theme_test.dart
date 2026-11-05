import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/theme/brand_theme.dart';
import 'package:full_stack/extensions/theme/design_tokens.dart';
import 'package:full_stack/extensions/theme/semantic_colors.dart';
import 'package:full_stack/extensions/theme/text_styles.dart';
import 'package:full_stack/extensions/theme/theme_config.dart';

void main() {
  test('builds light and dark themes from the config', () {
    final brand = BrandTheme(ThemeConfig.defaults);

    expect(brand.light.brightness, Brightness.light);
    expect(brand.dark.brightness, Brightness.dark);
    expect(brand.light.useMaterial3, isTrue);
    expect(brand.light.colorScheme.primary, isNot(brand.dark.colorScheme.primary));
    expect(brand.light.scaffoldBackgroundColor, brand.light.colorScheme.surface);
    expect(brand.dark.scaffoldBackgroundColor, brand.dark.colorScheme.surface);
  });

  test('applies the typography scale', () {
    final brand = BrandTheme(ThemeConfig.defaults);

    expect(brand.light.textTheme.displaySmall?.fontWeight, FontWeight.w800);
    expect(brand.light.textTheme.headlineSmall?.fontWeight, FontWeight.w700);
    expect(brand.light.textTheme.titleLarge?.fontWeight, FontWeight.w600);
    expect(
      brand.light.textTheme.bodyMedium?.color,
      brand.light.colorScheme.onSurface,
    );
  });

  test('installs design tokens and semantic colors', () {
    final brand = BrandTheme(ThemeConfig.defaults);
    final spacing = brand.light.extension<AppSpacing>();
    final radius = brand.light.extension<AppRadius>();

    expect(spacing, isNotNull);
    expect(spacing?.md, AppSpacing.comfortable.md);
    expect(radius?.md, 14);
    expect(brand.light.extension<SemanticColors>(), same(SemanticColors.light));
    expect(brand.dark.extension<SemanticColors>(), same(SemanticColors.dark));
  });

  test('compact density tightens spacing and visual density', () {
    final brand = BrandTheme(
      const ThemeConfig(
        seedColor: Color(0xFF0F766E),
        density: ThemeDensity.compact,
      ),
    );

    expect(brand.light.visualDensity, VisualDensity.compact);
    expect(brand.light.extension<AppSpacing>()?.md, AppSpacing.compact.md);
  });

  test('a custom seed changes the generated palette', () {
    final teal = BrandTheme(ThemeConfig.defaults);
    final blue = BrandTheme(const ThemeConfig(seedColor: Color(0xFF1D4ED8)));

    expect(blue.light.colorScheme.primary, isNot(teal.light.colorScheme.primary));
  });

  test('high contrast themes keep the requested brightness', () {
    final brand = BrandTheme(ThemeConfig.defaults);

    expect(brand.lightHighContrast.brightness, Brightness.light);
    expect(brand.darkHighContrast.brightness, Brightness.dark);
  });

  test('AppTextStyles applies the configured font family', () {
    final base = ThemeData(useMaterial3: true).textTheme;
    final textTheme = AppTextStyles.build(
      base: base,
      colors: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
      fontFamily: 'Inter',
    );

    expect(textTheme.bodyMedium?.fontFamily, 'Inter');
  });
}
