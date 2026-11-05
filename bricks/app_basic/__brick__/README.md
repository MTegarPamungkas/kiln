# {{name}}

A Flutter app generated with Kiln.

## Running

```bash
flutter pub get
flutter run
```

## Structure

{{#minimal}}
- `lib/app/` — root wiring only: registry scope, lifecycle, and MaterialApp
  seams. The SDK does not own navigation or feature pages.
- `lib/features/home/` — the starting page owned by the application.
- `lib/core/` — theme, the `CoreCopy` seam filled by the l10n extension, and
  error handling.
{{/minimal}}
{{^minimal}}
- `lib/app/` — app skeleton, registry, and MaterialApp shell. `KilnApp`
  forwards the Flutter lifecycle to `LifecycleController` and ends the session
  once `expiresAt` has passed. Register `AppHome` in the registry to replace
  the starter page without modifying the shell.
- `lib/core/` — theme, the `CoreCopy` seam filled by the l10n extension, and
  error handling.
{{/minimal}}
- `lib/l10n/` — ARB files; all app text comes from here.
- `lib/extensions/` — extension code installed via `kiln add`.
- `kiln.yaml` — project configuration and extension prompt answers.

Add extensions without editing the app skeleton:

```bash
kiln add dio
kiln add bloc
kiln doctor
```
