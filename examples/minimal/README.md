# minimal

A Flutter app generated with Kiln.

## Running

```bash
flutter pub get
flutter run
```

## Structure

- `lib/app/` — app skeleton, registry, and MaterialApp shell.
- `lib/core/` — theme, localization, and error handling.
- `lib/extensions/` — extension code installed via `kiln add`.
- `kiln.yaml` — project configuration and extension prompt answers.

Add extensions without editing the app skeleton:

```bash
kiln add dio
kiln add bloc
kiln doctor
```
