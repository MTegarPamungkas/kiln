# Changelog

## 0.1.2

- Installed automatically by `kiln create`; the app shell now requires
  `CoreCopy`, so shell and error-screen copy always come from ARB.

## 0.1.1

- Registers `LocalizedCoreCopy`, so shell and error-screen copy come from the
  ARB files instead of the hardcoded `AppStrings` fallback. The Indonesian
  `appTitle` is now `Aplikasi Kiln`.

## 0.1.0

- Rilis awal: controller locale dan penyimpanan pilihan lewat `Storage` bila
  tersedia.
- Terjemahan bersumber dari file ARB (`lib/l10n/app_<locale>.arb`) dan
  `flutter gen-l10n`; installer mengaktifkan `flutter.generate`.
- Resolusi locale regional seperti `id_ID` dipetakan ke `id`.
- Placeholder dan plural mengikuti aturan ARB/intl, bukan formatter sendiri.
- Format tanggal/angka/mata uang menurut locale, dan pesan ramah untuk setiap
  `FailureCode` dari ARB.
- Widget `LanguageSwitcher` dalam gaya dropdown dan segmented.
