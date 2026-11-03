# Adding a language

Follow these steps when adding a new language, for example French (`fr`).

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_fr.arb`.
2. Change `@@locale` to `fr` and translate every value. Do not change key names
   or `@key` metadata.
3. Add `fr` to the `locales` prompt in `extension.yaml` if that language is
   selected at install time:

   ```yaml
   options:
     - id
     - en
     - fr
   ```

4. Run the generator:

   ```bash
   flutter gen-l10n
   ```

   `flutter pub get` also runs the generator because `flutter.generate` is
   enabled.

5. Add the native language name to the `_languageNames` map in
   `L10nConfig.supportedLocales`; the application renders its own picker.
6. Run the tests:

   ```bash
   flutter test test/extensions/l10n
   ```

`l10n_coverage_test.dart` compares ARB keys across languages. Placeholder and
plural metadata must be copied along so gen-l10n produces the same signature.

## Notes

- Language codes follow BCP-47 (`id`, `en`, `pt`, `pt_BR`). Resolution matches
  the language first, so `id_ID` uses the `id` ARB.
- Do not change keys that the app already uses. Add new keys to all ARB files.
- The `lib/l10n/generated` folder is generated output; do not edit it manually.
