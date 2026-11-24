import 'package:full_stack/core/theme/app_theme_config.dart';
import 'package:kiln_core/kiln_core.dart';

import 'brand_theme.dart';
import 'theme_config.dart';
import 'theme_mode_controller.dart';
import 'theme_mode_store.dart';
import 'theme_support.dart';

/// Registers the brand theme, its settings, and the live theme mode.
final class ThemeModule extends KilnModule {
  ThemeModule();

  ThemeModeController? _controller;

  @override
  String get id => 'theme';

  @override
  Set<String> get provides => const <String>{'theme'};

  @override
  Set<String> get optionalRequires => const <String>{'storage'};

  @override
  void register(Registry registry) {
    final config = ThemeConfig.defaults;
    final brand = BrandTheme(config);
    final storage = registry.readOrNull<Storage>();
    final store = storage == null ? null : ThemeModeStore(storage: storage);
    final controller = ThemeModeController(store: store);
    _controller = controller;

    registry
      ..registerSingleton<ThemeConfig>(config)
      ..registerSingleton<BrandTheme>(brand)
      ..registerSingleton<ThemeModeController>(controller)
      ..registerSingleton<ThemeSupport>(
        ThemeSupport(config: config, persisted: store != null),
      )
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
  SupportInfo support(Registry registry) {
    return registry.read<ThemeSupport>().info;
  }

  @override
  Future<void> ready(Registry registry) async {
    try {
      await registry.read<ThemeModeController>().load();
    } on Object {
      // A saved preference must never block application startup.
    }
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }
}
