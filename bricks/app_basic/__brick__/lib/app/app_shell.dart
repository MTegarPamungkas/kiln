import 'package:flutter/material.dart';

import '../core/l10n/app_localizations_config.dart';
import '../core/l10n/core_copy.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_theme_config.dart';
{{^minimal}}
import 'app_home.dart';
{{/minimal}}
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
    {{#minimal}}
    final resolvedHome = home ?? const SizedBox.shrink();
    {{/minimal}}
    {{^minimal}}
    final resolvedHome =
        home ??
        (registry.readOrNull<AppHome>() ?? const StarterHome()).build(context);
    {{/minimal}}
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

{{^minimal}}
/// Default [AppHome] used when the application registers none.
final class StarterHome implements AppHome {
  const StarterHome();

  @override
  Widget build(BuildContext context) => const StarterPage();
}

/// Landing page used until a navigation or feature extension is installed.
class StarterPage extends StatelessWidget {
  const StarterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final copy = RegistryScope.read<CoreCopy>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surface,
              colors.primaryContainer.withValues(alpha: 0.35),
              colors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: colors.onPrimary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      copy.readyTitle(context),
                      key: const Key('kiln-starter-title'),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      copy.readyBody(context),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.terminal_rounded, color: colors.primary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              copy.starterHint(context),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

{{/minimal}}
