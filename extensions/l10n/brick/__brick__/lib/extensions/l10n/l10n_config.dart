import 'dart:ui' show Locale;

import 'locale_resolution.dart';

/// Typed localization settings produced from the install prompts.
final class L10nConfig {
  const L10nConfig({
    this.supportedLocales = defaultLocales,
    this.fallbackLocale = defaultFallback,
  });

  /// Locales selected during `kiln add l10n`.
  static const List<Locale> defaultLocales = <Locale>[
{{#locales}}    Locale('{{.}}'),
{{/locales}}  ];

  /// Locale used when the device locale is not supported.
  static const Locale defaultFallback = Locale('{{{fallback_locale}}}');

  /// Prompt defaults bundled with the extension.
  static const L10nConfig defaults = L10nConfig();

  final List<Locale> supportedLocales;
  final Locale fallbackLocale;

  /// Fallback locale that is guaranteed to be part of [supportedLocales].
  Locale get resolvedFallback {
    for (final locale in supportedLocales) {
      if (_matchesLanguage(locale, fallbackLocale)) {
        return locale;
      }
    }
    if (supportedLocales.isEmpty) {
      return fallbackLocale;
    }
    return supportedLocales.first;
  }

  /// Whether [locale] can be served by this configuration.
  bool supports(Locale locale) {
    for (final supported in supportedLocales) {
      if (_matchesLanguage(supported, locale)) {
        return true;
      }
    }
    return false;
  }

  /// Returns the supported locale that matches [locale].
  ///
  /// The returned locale is one of [supportedLocales], so `id_ID` becomes
  /// `Locale('id')` when only Indonesian is configured. Unsupported locales
  /// resolve to [resolvedFallback].
  Locale canonical(Locale locale) => resolve(locale);

  /// Resolves a device locale to a locale this application can display.
  Locale resolve(Locale? deviceLocale) {
    return LocaleResolution.resolve(
      deviceLocale,
      supported: supportedLocales,
      fallback: resolvedFallback,
    );
  }

  static bool _matchesLanguage(Locale left, Locale right) {
    return left.languageCode.toLowerCase() == right.languageCode.toLowerCase();
  }
}
