# full_stack

A Flutter app generated with Kiln.

## Running

```bash
flutter pub get
flutter run
```

## Structure

- `lib/app/` — app skeleton, registry, and MaterialApp shell.
- `lib/core/` — theme, localization, error handling, and the `bloc` runtime
  (`core/bloc/base_bloc.dart`, `async_bloc.dart`, `session_bloc.dart`,
  `app_bloc_observer.dart`) plus the use-case contracts in
  `lib/core/architecture/`.
- `lib/extensions/` — extension code installed via `kiln add`.
- `lib/features/notes/` — the sample feature the `bloc` extension installs,
  split into `domain/` (entity, repository contract, use cases), `data/`
  (model, datasource, repository implementation) and `presentation/`
  (`bloc/`, `screens/`, `widgets/`). `feature.dart` is its barrel.
- `ARCHITECTURE.md` — the layer rules the feature folder follows.
- `kiln.yaml` — project configuration and extension prompt answers.

The notes screen is the starting point to copy when adding your own feature:
start from `lib/features/notes/` and follow `ARCHITECTURE.md`.

Add extensions without editing the app skeleton:

```bash
kiln add dio
kiln add bloc
kiln doctor
```
