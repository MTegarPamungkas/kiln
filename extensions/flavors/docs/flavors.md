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

## Flavor indicator

The extension exposes the active `AppFlavor` as data; it does not add a banner.
Applications that want an indicator wrap their shell themselves:

```dart
Banner(
  location: BannerLocation.topStart,
  message: flavor == AppFlavor.production ? '' : flavor.label,
  child: app,
)
```

## Release guard

Release builds with a non-production flavor are recorded as a warning through
`AppLogger` when the logger extension is installed.
