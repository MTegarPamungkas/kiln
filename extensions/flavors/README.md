# flavors

Dart flavor values, per-flavor entry points, and VS Code launch configuration.

- `AppFlavors` defines development, staging, and production.
- `main_development.dart`, `main_staging.dart`, and `main_production.dart`
  run the app with their respective flavor.
- `FlavorsModule` adds `FlavorBanner` to the `app.wrappers` slot.
- `ReleaseGuard` warns about release builds that use a non-production
  flavor.
- `FlavorX.valueFor` selects a value per flavor.

Flavors here are Dart values, not native Android/iOS product flavors.
See [docs/native-flavors-not-included.md](docs/native-flavors-not-included.md).
