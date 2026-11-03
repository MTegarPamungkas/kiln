# Changelog

## 0.1.4

- Map `support.unsupported_platform` and `support.unsupported_device` to a
  dedicated localized message.

## 0.1.3

- Failure messages now follow the platform locale when the app has no explicit
  locale choice, matching `MaterialApp` locale resolution instead of always
  using the fallback locale.

## 0.1.2

- Installed automatically by `kiln create`; the app shell now requires
  `CoreCopy`, so shell and error-screen copy always come from ARB.

## 0.1.1

- Registers `LocalizedCoreCopy`, so shell and error-screen copy come from the
  ARB files instead of the hardcoded `AppStrings` fallback. The Indonesian
  `appTitle` is now `Aplikasi Kiln`.

## 0.1.0

- Initial release: locale controller and persisting the choice through
  `Storage` when available.
- Translations sourced from ARB files (`lib/l10n/app_<locale>.arb`) and
  `flutter gen-l10n`; the installer enables `flutter.generate`.
- Regional locale resolution such as `id_ID` maps to `id`.
- Placeholders and plurals follow ARB/intl rules, not a custom formatter.
- Date/number/currency formatting per locale, and friendly messages for each
  `FailureCode` from ARB.
- `LanguageSwitcher` widget in dropdown and segmented styles.
