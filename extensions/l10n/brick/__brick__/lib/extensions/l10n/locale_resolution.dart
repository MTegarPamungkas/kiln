import 'dart:ui' show Locale;

/// Maps device locales onto the locales an application can display.
abstract final class LocaleResolution {
  /// Resolves [deviceLocale] against [supported].
  ///
  /// Matching order is exact tag, language plus country, then language. This
  /// turns `id_ID` into `Locale('id')` when only `id` is supported. A `null`
  /// device locale and unsupported languages resolve to [fallback].
  static Locale resolve(
    Locale? deviceLocale, {
    required Iterable<Locale> supported,
    required Locale fallback,
  }) {
    final locales = supported.toList(growable: false);
    if (locales.isEmpty) {
      return fallback;
    }
    if (deviceLocale == null) {
      return _firstMatching(locales, fallback) ?? locales.first;
    }

    for (final locale in locales) {
      if (_isExactMatch(locale, deviceLocale)) {
        return locale;
      }
    }
    for (final locale in locales) {
      if (_matchesCountry(locale, deviceLocale)) {
        return locale;
      }
    }
    for (final locale in locales) {
      if (_matchesLanguage(locale, deviceLocale)) {
        return locale;
      }
    }
    return _firstMatching(locales, fallback) ?? locales.first;
  }

  /// Whether [supported] can serve [requested].
  static bool supports(Locale supported, Locale requested) {
    return _matchesLanguage(supported, requested);
  }

  static Locale? _firstMatching(Iterable<Locale> locales, Locale wanted) {
    for (final locale in locales) {
      if (_matchesLanguage(locale, wanted)) {
        return locale;
      }
    }
    return null;
  }

  static bool _isExactMatch(Locale supported, Locale requested) {
    return _matchesLanguage(supported, requested) &&
        _samePart(supported.scriptCode, requested.scriptCode) &&
        _samePart(supported.countryCode, requested.countryCode);
  }

  static bool _matchesCountry(Locale supported, Locale requested) {
    return _matchesLanguage(supported, requested) &&
        _samePart(supported.countryCode, requested.countryCode);
  }

  static bool _matchesLanguage(Locale supported, Locale requested) {
    return supported.languageCode.toLowerCase() ==
        requested.languageCode.toLowerCase();
  }

  static bool _samePart(String? left, String? right) {
    if (left == null || left.isEmpty) {
      return true;
    }
    return left.toLowerCase() == (right ?? '').toLowerCase();
  }
}
