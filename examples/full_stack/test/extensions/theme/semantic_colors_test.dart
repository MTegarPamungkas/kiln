import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_stack/extensions/theme/semantic_colors.dart';

void main() {
  test('exposes success, warning, and info for both brightnesses', () {
    const light = SemanticColors.light;
    const dark = SemanticColors.dark;

    expect(SemanticColors.forBrightness(Brightness.light), same(light));
    expect(SemanticColors.forBrightness(Brightness.dark), same(dark));
    expect(light.success, isNot(light.warning));
    expect(light.warning, isNot(light.info));
    expect(dark.success, isNot(light.success));
    expect(dark.onInfo, isNot(light.onInfo));
  });

  test('is available as a ThemeExtension', () {
    final theme = ThemeData(
      extensions: const <ThemeExtension<dynamic>>[SemanticColors.light],
    );

    expect(theme.extension<SemanticColors>(), same(SemanticColors.light));
  });

  test('copyWith replaces only the given colors', () {
    final copied = SemanticColors.light.copyWith(
      success: const Color(0xFF166534),
    );

    expect(copied.success, const Color(0xFF166534));
    expect(copied.onSuccess, SemanticColors.light.onSuccess);
    expect(copied.warning, SemanticColors.light.warning);
  });

  test('lerp blends between palettes and ignores other types', () {
    final halfway = SemanticColors.light.lerp(SemanticColors.dark, 0.5);

    expect(
      halfway.success,
      Color.lerp(
        SemanticColors.light.success,
        SemanticColors.dark.success,
        0.5,
      ),
    );
    expect(SemanticColors.light.lerp(null, 0.5), same(SemanticColors.light));
  });
}
