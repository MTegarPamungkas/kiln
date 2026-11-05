import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/app/app.dart';
import 'package:with_appwrite/core/theme/app_theme_config.dart';

void main() {
  testWidgets('follows a live theme mode from the theme extension', (
    tester,
  ) async {
    final mode = ValueNotifier<ThemeMode>(ThemeMode.light);
    final registry = GetItRegistry()
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<AppThemeConfig>(
        AppThemeConfig(modeListenable: mode),
      );

    await tester.pumpWidget(KilnApp(registry: registry));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });
}
