# Flavors

```bash
flutter run -t lib/main_development.dart --dart-define-from-file=env/development.json
flutter run -t lib/main_staging.dart --dart-define-from-file=env/staging.json
flutter run -t lib/main_production.dart --dart-define-from-file=env/production.json
```

`runKilnApp(flavor)` mendaftarkan `AppFlavor` sebelum modul lain berjalan,
sehingga logger, analytics, dan extension lain dapat membaca flavor saat
register.

## Pemakaian

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

`FlavorBanner` menampilkan pita DEV atau STG di pojok kiri atas. Production
tidak menampilkan pita. Module menambahkan banner lewat slot `app.wrappers`,
jadi `app_shell.dart` tidak perlu diedit.

## Release guard

Build release dengan flavor non-production dicatat sebagai warning melalui
`AppLogger` bila extension logger terpasang.
