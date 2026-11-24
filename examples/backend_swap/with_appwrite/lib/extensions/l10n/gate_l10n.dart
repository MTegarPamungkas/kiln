import 'dart:ui' show Locale;

import 'package:kiln_core/kiln_core.dart';

import 'locale_controller.dart';

/// Gate verbs for the locale capability.
///
/// Lets the app switch the locale (or follow the system) with a single call
/// returning a [Result]. The SDK owns the choice, not the UI. The verbs report
/// a [PersistOutcome] so the app can warn the user when a choice applies now
/// but will not survive a restart.
extension GateL10nX on Gate {
  LocaleController get localeController => use<LocaleController>();

  Locale? get locale => localeController.locale;

  /// Locales the application ships with, for building a language picker.
  List<Locale> get supportedLocales => localeController.config.supportedLocales;

  Future<Result<PersistOutcome>> setLocale(Locale? locale) =>
      call(() => localeController.setLocale(locale));

  Future<Result<PersistOutcome>> followSystemLocale() =>
      call(localeController.followSystem);
}
