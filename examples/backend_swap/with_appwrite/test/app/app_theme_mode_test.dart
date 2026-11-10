import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/core/l10n/core_copy.dart';
import 'package:with_appwrite/core/theme/app_theme_config.dart';

import 'support/app_fixture.dart';
import 'support/test_core_copy.dart';

void main() {
  testWidgets('follows a live theme mode from the theme extension', (
    tester,
  ) async {
    final mode = ValueNotifier<ThemeMode>(ThemeMode.light);
    final session = SessionController();
    addTearDown(session.dispose);
    final registry = GetItRegistry()
      ..registerSingleton<CoreCopy>(const TestCoreCopy())
      ..registerSingleton<SessionController>(session)
      ..registerSingleton<LifecycleController>(LifecycleController())
      ..registerSingleton<Clock>(const SystemClock())
      ..registerSingleton<SlotRegistry>(SlotRegistry())
      ..registerSingleton<AppThemeConfig>(AppThemeConfig(modeListenable: mode));

    await tester.pumpWidget(buildTestApp(registry));
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
