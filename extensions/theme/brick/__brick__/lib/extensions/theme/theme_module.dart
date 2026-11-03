import 'package:{{app_name}}/core/theme/app_theme_config.dart';
import 'package:kiln_core/kiln_core.dart';

import 'brand_theme.dart';
import 'theme_config.dart';
import 'theme_mode_controller.dart';
import 'theme_mode_store.dart';

/// Registers the brand theme, its settings, and the live theme mode.
final class ThemeModule extends KilnModule {
  const ThemeModule();

  @override
  String get id => 'theme';

  @override
  Set<String> get provides => const <String>{'theme'};

  @override
  void register(Registry registry) {
    final config = ThemeConfig.defaults;
    final brand = BrandTheme(config);
    final storage = registry.readOrNull<Storage>();
    final store = storage == null ? null : ThemeModeStore(storage: storage);
    final controller = ThemeModeController(store: store);

    registry
      ..registerSingleton<ThemeConfig>(config)
      ..registerSingleton<BrandTheme>(brand)
      ..registerSingleton<ThemeModeController>(controller)
      ..registerSingleton<AppThemeConfig>(
        AppThemeConfig(
          light: brand.light,
          dark: brand.dark,
          mode: controller.mode,
          modeListenable: controller.modeListenable,
        ),
      );

    if (store != null) {
      registry.registerSingleton<ThemeModeStore>(store);
    }
  }

  @override
  Future<void> ready(Registry registry) async {
    try {
      await registry.read<ThemeModeController>().load();
    } on Object {
      // A saved preference must never block application startup.
    }
  }
}
