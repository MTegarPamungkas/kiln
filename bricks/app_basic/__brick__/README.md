# {{name}}

A Flutter app generated with Kiln.

## Running

```bash
flutter pub get
flutter run
```

## Structure

Read [ARCHITECTURE.md](ARCHITECTURE.md) for the layer rules and the folder map
that every feature follows.

{{#minimal}}
- `lib/app/` — root wiring only: registry scope, lifecycle, and MaterialApp
  seams. The SDK does not own navigation or feature pages.
- `lib/core/` — shared contracts (`architecture/`), error handling, and the
  theme and text seams filled by extensions.
- `lib/features/home/` — the starting feature owned by the application; replace
  it with your first real feature.
{{/minimal}}
{{^minimal}}
- `lib/app/` — app skeleton, registry, and MaterialApp shell. `KilnApp`
  forwards the Flutter lifecycle to `LifecycleController` and ends the session
  once `expiresAt` has passed. Register `AppHome` in the registry to replace
  the starter page without modifying the shell.
- `lib/core/` — shared contracts (`architecture/`), error handling, and the
  theme and text seams filled by extensions.
- `lib/features/` — your code, one folder per feature, split into `domain`,
  `data`, and `presentation`.
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
