import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/extensions/theme/brand_theme.dart';
import 'package:{{app_name}}/extensions/theme/semantic_colors.dart';
import 'package:{{app_name}}/extensions/theme/theme_config.dart';

/// Relative luminance from the WCAG 2.1 definition.
double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG contrast ratio between two opaque colors.
double contrastRatio(Color foreground, Color background) {
  final first = _luminance(foreground);
  final second = _luminance(background);
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const minimum = 4.5;

  test('Material text pairs meet WCAG AA', () {
    final brand = BrandTheme(ThemeConfig.defaults);

    for (final theme in <ThemeData>[brand.light, brand.dark]) {
      final colors = theme.colorScheme;
      expect(
        contrastRatio(colors.onSurface, colors.surface),
        greaterThanOrEqualTo(minimum),
        reason: 'onSurface on surface (${theme.brightness.name})',
      );
      expect(
        contrastRatio(colors.onPrimary, colors.primary),
        greaterThanOrEqualTo(minimum),
        reason: 'onPrimary on primary (${theme.brightness.name})',
      );
      expect(
        contrastRatio(colors.onError, colors.error),
        greaterThanOrEqualTo(minimum),
        reason: 'onError on error (${theme.brightness.name})',
      );
      expect(
        contrastRatio(colors.onSecondaryContainer, colors.secondaryContainer),
        greaterThanOrEqualTo(minimum),
        reason: 'onSecondaryContainer (${theme.brightness.name})',
      );
    }
  });

  test('semantic colors meet WCAG AA', () {
    for (final semantic in <SemanticColors>[
      SemanticColors.light,
      SemanticColors.dark,
    ]) {
      expect(
        contrastRatio(semantic.onSuccess, semantic.success),
        greaterThanOrEqualTo(minimum),
        reason: 'success pair',
      );
      expect(
        contrastRatio(semantic.onWarning, semantic.warning),
        greaterThanOrEqualTo(minimum),
        reason: 'warning pair',
      );
      expect(
        contrastRatio(semantic.onInfo, semantic.info),
        greaterThanOrEqualTo(minimum),
        reason: 'info pair',
      );
    }
  });

  test('high contrast themes improve or keep the body contrast', () {
    final brand = BrandTheme(ThemeConfig.defaults);
    final standard = contrastRatio(
      brand.light.colorScheme.onSurface,
      brand.light.colorScheme.surface,
    );
    final high = contrastRatio(
      brand.lightHighContrast.colorScheme.onSurface,
      brand.lightHighContrast.colorScheme.surface,
    );

    expect(high, greaterThanOrEqualTo(standard));
  });
}
