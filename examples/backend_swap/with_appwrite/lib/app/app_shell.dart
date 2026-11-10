import 'package:flutter/material.dart';

import '../core/l10n/app_localizations_config.dart';
import '../core/l10n/core_copy.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_theme_config.dart';

import 'app_wrappers.dart';
import 'registry_scope.dart';

/// Builds MaterialApp from the registry seams and applies app wrappers.
class AppShell extends StatelessWidget {
  const AppShell({this.home, super.key});

  /// Root page supplied by the minimal template.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    final registry = RegistryScope.of(context);
    final themeConfig = registry.readOrNull<AppThemeConfig>();
    final localizations = registry.readOrNull<AppLocalizationsConfig>();
    final copy = registry.read<CoreCopy>();
    final router = registry.readOrNull<RouterConfig<Object>>();

    final resolvedHome = home ?? const SizedBox.shrink();

    final wrappers = appWrappers(registry);
    final supportedLocales =
        localizations?.supportedLocales ??
        AppLocalizationsConfig.defaultLocales;

    Widget buildApp(ThemeMode mode, Locale? locale) {
      final theme = themeConfig?.light ?? AppTheme.light;
      final darkTheme = themeConfig?.dark ?? AppTheme.dark;

      Widget app;
      if (router != null) {
        app = MaterialApp.router(
          onGenerateTitle: copy.appTitle,
          theme: theme,
          darkTheme: darkTheme,
          themeMode: mode,
          routerConfig: router,
          locale: locale,
          localizationsDelegates: localizations?.delegates,
          supportedLocales: supportedLocales,
        );
      } else {
        app = MaterialApp(
          onGenerateTitle: copy.appTitle,
          theme: theme,
          darkTheme: darkTheme,
          themeMode: mode,
          locale: locale,
          localizationsDelegates: localizations?.delegates,
          supportedLocales: supportedLocales,
          home: resolvedHome,
        );
      }

      for (final wrapper in wrappers.reversed) {
        app = wrapper(context, app);
      }
      return app;
    }

    final themeListenable = themeConfig?.modeListenable;
    final localeListenable = localizations?.localeListenable;
    final listenables = <Listenable>[?themeListenable, ?localeListenable];
    if (listenables.isEmpty) {
      return buildApp(
        themeConfig?.mode ?? ThemeMode.system,
        localizations?.locale,
      );
    }
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) => buildApp(
        themeConfig?.currentMode ?? ThemeMode.system,
        localizations?.currentLocale,
      ),
    );
  }
}
