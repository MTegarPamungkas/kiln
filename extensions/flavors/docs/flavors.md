# Flavors

```bash
flutter run -t lib/main_development.dart --dart-define-from-file=env/development.json
flutter run -t lib/main_staging.dart --dart-define-from-file=env/staging.json
flutter run -t lib/main_production.dart --dart-define-from-file=env/production.json
```

`runKilnApp(flavor)` registers `AppFlavor` before other modules run, so the
logger, analytics, and other extensions can read the flavor at register time.

## Usage

```dart
final flavor = registry.read<AppFlavor>();

final apiUrl = flavor.valueFor<String>(
  development: 'https://dev.api.kiln.dev',
  staging: 'https://stg.api.kiln.dev',
  production: 'https://api.kiln.dev',
  orElse: 'https://api.kiln.dev',
);
```

## Banner

`FlavorBanner` shows a DEV or STG ribbon in the top-left corner. Production
shows no ribbon. The module adds the banner through the `app.wrappers` slot,
so `app_shell.dart` does not need to be edited.

## Release guard

Release builds with a non-production flavor are recorded as a warning through
`AppLogger` when the logger extension is installed.
