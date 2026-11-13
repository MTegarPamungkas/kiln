# Changelog

## 0.2.1

- The module orders itself after the logger, so the Bloc observer is
  attached when both extensions are installed.

## 0.2.0

- Breaking: the brick no longer ships Cubit scaffolding. `base_cubit.dart`,
  `async_cubit.dart`, and `session_cubit.dart` are replaced by `base_bloc.dart`,
  `async_bloc.dart`, and `session_bloc.dart`; migrate by moving the state type
  and the fetcher into a sealed event hierarchy.
- `BaseBloc` keeps the Kiln `Result` helpers: `runGuarded` turns a thrown value
  into an `Err`, and `reportResult` emits only on failure so a domain stream
  stays the single source of truth.
- `AsyncBloc` adds `autoLoad`, `refresh()`, and `retry()` over the unchanged
  sealed `AsyncState`.
- `SessionBloc` mirrors `SessionController` through `SessionStatusChanged` and
  `SessionSynced` events; `bloc_providers.dart` provides it globally.
- New `lib/features/notes/` sample feature in clean-architecture form:
  `domain/{entities,repositories,usecases}`, `data/{models,datasources,repositories}`,
  `presentation/{bloc,screens,widgets}`, and a `feature.dart` composition barrel.
- New generated-app tests under `test/features/notes/`.

## 0.1.0

- Initial release.
