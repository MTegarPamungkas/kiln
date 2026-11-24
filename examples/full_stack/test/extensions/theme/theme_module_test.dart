import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:kiln_testing/kiln_testing.dart';
import 'package:full_stack/core/theme/app_theme_config.dart';
import 'package:full_stack/extensions/theme/theme_config.dart';
import 'package:full_stack/extensions/theme/theme_mode_controller.dart';
import 'package:full_stack/extensions/theme/theme_mode_store.dart';
import 'package:full_stack/extensions/theme/theme_module.dart';
import 'package:full_stack/extensions/theme/theme_support.dart';

void main() {
  test('declares the optional dependency that determines readiness', () {
    expect(ThemeModule().optionalRequires, contains('storage'));
  });

  test('registers the theme seams without storage', () {
    final registry = GetItRegistry();

    ThemeModule().register(registry);

    final appTheme = registry.read<AppThemeConfig>();
    final controller = registry.read<ThemeModeController>();
    final config = registry.read<ThemeConfig>();

    expect(config.cornerRadius, 14);
    expect(registry.read<ThemeSupport>(), isA<ThemeSupport>());
    expect(appTheme.mode, ThemeMode.system);
    expect(appTheme.currentMode, ThemeMode.system);
    expect(appTheme.modeListenable, same(controller.modeListenable));
    expect(appTheme.light.brightness, Brightness.light);
    expect(appTheme.dark.brightness, Brightness.dark);
    expect(registry.readOrNull<ThemeModeStore>(), isNull);
  });

  test('module disposes its controller once', () async {
    final registry = GetItRegistry();
    final module = ThemeModule()..register(registry);
    final controller = registry.read<ThemeModeController>();

    await module.dispose();
    await module.dispose();
    await controller.setMode(ThemeMode.dark);

    expect(controller.mode, ThemeMode.system);
  });

  test('registers the store and restores the saved mode on ready', () async {
    final storage = InMemoryStorage(<String, String>{'theme.mode': 'dark'});
    final registry = GetItRegistry()..registerSingleton<Storage>(storage);
    final module = ThemeModule();

    module.register(registry);
    final controller = registry.read<ThemeModeController>();
    expect(registry.readOrNull<ThemeModeStore>(), isNotNull);
    expect(controller.mode, ThemeMode.system);

    await module.ready(registry);

    expect(controller.mode, ThemeMode.dark);
    expect(registry.read<AppThemeConfig>().currentMode, ThemeMode.dark);
  });
}
