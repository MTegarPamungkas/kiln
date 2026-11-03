# Run configurations

`.vscode/launch.json` contains three configurations:

- Development -> `lib/main_development.dart`
- Staging -> `lib/main_staging.dart`
- Production -> `lib/main_production.dart`

Each one uses `--dart-define-from-file=env/<flavor>.json`.

## Terminal

```bash
flutter run -t lib/main_development.dart --dart-define-from-file=env/development.json
```

## IntelliJ / Android Studio

Create a Flutter Run Configuration with:

- Dart entrypoint: `lib/main_staging.dart`
- Additional arguments: `--dart-define-from-file=env/staging.json`

Do not use `flutter run` without `-t` for a non-development flavor; the default
entry point is `lib/main.dart` without a flavor.
