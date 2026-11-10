import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/theme/brand_theme.dart';
import 'package:full_stack/extensions/theme/theme_config.dart';

void main() {
  final theme = BrandTheme(ThemeConfig.defaults).light;
  final colors = theme.colorScheme;

  test('themes the app bar', () {
    expect(theme.appBarTheme.backgroundColor, colors.surface);
    expect(theme.appBarTheme.foregroundColor, colors.onSurface);
    expect(theme.appBarTheme.centerTitle, isFalse);
    expect(theme.appBarTheme.titleTextStyle?.fontWeight, FontWeight.w600);
    expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
  });

  test('themes the buttons', () {
    final empty = <WidgetState>{};
    final filledShape = theme.filledButtonTheme.style?.shape?.resolve(empty);
    final outlinedShape = theme.outlinedButtonTheme.style?.shape?.resolve(
      empty,
    );

    expect(filledShape, isA<RoundedRectangleBorder>());
    expect(
      (filledShape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(14),
    );
    expect(
      theme.filledButtonTheme.style?.padding?.resolve(empty),
      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
    expect(
      (outlinedShape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(14),
    );
    expect(theme.elevatedButtonTheme.style, isA<ButtonStyle>());
    expect(theme.textButtonTheme.style, isA<ButtonStyle>());
  });

  test('themes text inputs', () {
    final decoration = theme.inputDecorationTheme;
    final border = decoration.border;

    expect(decoration.filled, isTrue);
    expect(
      decoration.contentPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
    expect(border, isA<OutlineInputBorder>());
    expect(
      (border! as OutlineInputBorder).borderRadius,
      BorderRadius.circular(14),
    );
    expect(decoration.focusedBorder, isA<OutlineInputBorder>());
  });

  test('themes cards and dialogs', () {
    expect(theme.cardTheme.color, colors.surfaceContainerLow);
    expect(theme.cardTheme.elevation, 0);
    expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.dialogTheme.backgroundColor, colors.surfaceContainerLow);
    expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
  });

  test('themes snack bars and navigation bars', () {
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(theme.snackBarTheme.backgroundColor, colors.inverseSurface);
    expect(theme.snackBarTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.navigationBarTheme.height, 68);
    expect(
      theme.navigationBarTheme.backgroundColor,
      colors.surfaceContainerLow,
    );
    expect(theme.navigationBarTheme.indicatorColor, colors.secondaryContainer);
  });

  test('compact density lowers component spacing', () {
    final compact = BrandTheme(
      const ThemeConfig(
        seedColor: Color(0xFF0F766E),
        density: ThemeDensity.compact,
      ),
    ).light;

    expect(compact.navigationBarTheme.height, 60);
    expect(
      compact.inputDecorationTheme.contentPadding,
      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
    expect(compact.visualDensity, VisualDensity.compact);
  });
}
