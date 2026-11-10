import 'dart:ui' show PlatformDispatcher;

import 'package:kiln_core/kiln_core.dart';
import 'package:with_appwrite/core/error/failure_presenter.dart';
import 'package:with_appwrite/core/l10n/app_localizations_config.dart';
import 'package:with_appwrite/core/l10n/core_copy.dart';

import '../../l10n/generated/app_localizations.dart';
import 'failure_messages.dart';
import 'l10n_config.dart';
import 'l10n_support.dart';
import 'locale_controller.dart';
import 'locale_formatters.dart';
import 'locale_store.dart';
import 'localized_core_copy.dart';

/// Registers ARB-backed localizations, locale control, and failure messages.
final class L10nModule extends KilnModule {
  const L10nModule();

  @override
  String get id => 'l10n';

  @override
  Set<String> get provides => const <String>{'l10n'};

  @override
  Set<String> get optionalRequires => const <String>{'storage'};

  @override
  void register(Registry registry) {
    const config = L10nConfig.defaults;
    final storage = registry.readOrNull<Storage>();
    final store = storage == null ? null : LocaleStore(storage);
    final controller = LocaleController(config: config, store: store);
    final messages = L10nFailureMessages(
      config: config,
      resolveLocale: () =>
          controller.locale ?? PlatformDispatcher.instance.locale,
    );

    registry
      ..registerSingleton<L10nConfig>(config)
      ..registerSingleton<L10nSupport>(
        L10nSupport(config: config, persisted: store != null),
      )
      ..registerSingleton<LocaleController>(controller)
      ..registerSingleton<FailureMessages>(messages)
      ..registerSingleton<CoreCopy>(const LocalizedCoreCopy())
      ..registerSingleton<AppLocalizationsConfig>(
        AppLocalizationsConfig(
          delegates: AppLocalizations.localizationsDelegates,
          supportedLocales: config.supportedLocales,
          locale: controller.locale,
          localeListenable: controller.localeListenable,
        ),
      );

    if (store != null) {
      registry.registerSingleton<LocaleStore>(store);
    }
  }

  @override
  SupportInfo support(Registry registry) {
    return registry.read<L10nSupport>().info;
  }

  @override
  Future<void> ready(Registry registry) async {
    try {
      await LocaleFormatters.initialize();
    } on Object {
      // Date formatting falls back to English symbols when intl is not ready.
    }
    try {
      await registry.read<LocaleController>().load();
    } on Object {
      // A missing preference must not block startup.
    }
  }
}
