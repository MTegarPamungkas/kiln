# flavors

Dart flavor values, per-flavor entry points, and VS Code launch configuration.

- `AppFlavors` defines development, staging, and production.
- `main_development.dart`, `main_staging.dart`, and `main_production.dart`
  run the app with their respective flavor.
- The application reads `AppFlavor` and renders any flavor indicator itself.
- `ReleaseGuard` warns about release builds that use a non-production
  flavor.
- `FlavorX.valueFor` selects a value per flavor.

Flavors here are Dart values, not native Android/iOS product flavors.
See [docs/native-flavors-not-included.md](docs/native-flavors-not-included.md).

## Gate

```dart
final flavor = gate.flavor;          // AppFlavor
final isProduction = flavor.isProduction;
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
