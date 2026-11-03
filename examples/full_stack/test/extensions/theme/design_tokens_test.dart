import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/theme/design_tokens.dart';

void main() {
  test('AppSpacing exposes the comfortable scale', () {
    const spacing = AppSpacing.comfortable;

    expect(spacing.xs, 4);
    expect(spacing.sm, 8);
    expect(spacing.md, 16);
    expect(spacing.lg, 24);
    expect(spacing.xl, 32);
    expect(spacing.xxl, 48);
    expect(spacing.pagePadding, const EdgeInsets.all(24));
    expect(spacing.cardPadding, const EdgeInsets.all(16));
  });

  test('AppSpacing is available as a ThemeExtension', () {
    final theme = ThemeData(
      extensions: <ThemeExtension<dynamic>>[AppSpacing.compact],
    );

    expect(theme.extension<AppSpacing>()?.md, AppSpacing.compact.md);
    expect(theme.extension<AppSpacing>()?.md, 12);
  });

  test('AppSpacing copies and lerps values', () {
    final copied = AppSpacing.comfortable.copyWith(md: 20);
    final halfway = AppSpacing.comfortable.lerp(AppSpacing.compact, 0.5);

    expect(copied.md, 20);
    expect(copied.sm, 8);
    expect(halfway.md, 14);
    expect(AppSpacing.comfortable.lerp(null, 0.5).md, 16);
  });

  test('AppRadius derives every step from the base radius', () {
    final radius = AppRadius.fromCornerRadius(20);

    expect(radius.md, 20);
    expect(radius.sm, 12);
    expect(radius.lg, 28);
    expect(radius.xl, 40);
    expect(radius.mdBorder, BorderRadius.circular(20));
    expect(radius.pill, 999);
  });

  test('AppRadius clamps negative bases and is a ThemeExtension', () {
    final theme = ThemeData(
      extensions: <ThemeExtension<dynamic>>[
        AppRadius.fromCornerRadius(-4),
      ],
    );

    expect(theme.extension<AppRadius>()?.md, 0);
    expect(AppRadius.fromCornerRadius(10).copyWith(lg: 30).lg, 30);
    expect(
      AppRadius.fromCornerRadius(10).lerp(AppRadius.fromCornerRadius(20), 0.5).md,
      15,
    );
  });
}
