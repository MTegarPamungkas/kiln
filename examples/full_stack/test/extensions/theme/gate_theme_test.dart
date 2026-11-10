import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:full_stack/extensions/theme/gate_theme.dart';
import 'package:full_stack/extensions/theme/theme_mode_controller.dart';

void main() {
  test('gate switches the theme mode in one call', () async {
    final registry = GetItRegistry()
      ..registerSingleton<ThemeModeController>(
        ThemeModeController(initialMode: ThemeMode.light),
      );
    final gate = Gate(registry);

    expect(gate.themeMode, ThemeMode.light);

    final result = await gate.setThemeMode(ThemeMode.dark);

    expect(result, isA<Ok<void>>());
    expect(gate.themeMode, ThemeMode.dark);
  });
}
