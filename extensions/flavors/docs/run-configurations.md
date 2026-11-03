# Run configurations

`.vscode/launch.json` berisi tiga konfigurasi:

- Development -> `lib/main_development.dart`
- Staging -> `lib/main_staging.dart`
- Production -> `lib/main_production.dart`

Masing-masing memakai `--dart-define-from-file=env/<flavor>.json`.

## Terminal

```bash
flutter run -t lib/main_development.dart --dart-define-from-file=env/development.json
```

## IntelliJ / Android Studio

Buat Run Configuration Flutter dengan:

- Dart entrypoint: `lib/main_staging.dart`
- Additional arguments: `--dart-define-from-file=env/staging.json`

Jangan memakai `flutter run` tanpa `-t` untuk flavor non-development; entry
point default adalah `lib/main.dart` tanpa flavor.
