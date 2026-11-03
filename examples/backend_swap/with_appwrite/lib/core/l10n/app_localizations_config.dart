import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Localization seam filled by the `l10n` extension when it is installed.
class AppLocalizationsConfig {
  const AppLocalizationsConfig({
    this.delegates = const <LocalizationsDelegate<dynamic>>[],
    this.supportedLocales = defaultLocales,
    this.locale,
    this.localeListenable,
  });

  static const List<Locale> defaultLocales = <Locale>[
    Locale('id'),
    Locale('en'),
  ];

  final Iterable<LocalizationsDelegate<dynamic>> delegates;
  final List<Locale> supportedLocales;

  /// `null` means the application follows the device locale.
  final Locale? locale;

  /// Optional live locale supplied by a localization extension.
  final ValueListenable<Locale?>? localeListenable;

  Locale? get currentLocale => localeListenable?.value ?? locale;
}
