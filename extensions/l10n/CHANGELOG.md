# Changelog

## 0.1.2

- Prepend `GlobalMaterialLocalizations.delegate` from `package:material_ui` in `L10nModule` so Material widgets keep `MaterialLocalizations` on non-English locales (such as `id`) while `gen-l10n` still emits the deprecated `flutter_localizations` delegate.

## 0.1.1

- Repack archive with deterministic cross-OS gzip and without root `test/`.

## 0.1.0

- Fence overlapping locale loads and keep a rejected locale from invalidating
  a valid restore. Verify persistence failure recovery.

- Initial release.
- The module disposes its locale controller, and a stored-locale read that
  finishes after shutdown no longer touches the disposed notifier.
