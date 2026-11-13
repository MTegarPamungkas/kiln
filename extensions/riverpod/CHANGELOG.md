# Changelog

## 0.2.1

- The module orders itself after the logger and reports whether the
  provider observer is attached.

## 0.2.0

- New `lib/features/notes/` sample feature in clean-architecture form:
  `domain/{entities,repositories,usecases}`, `data/{models,datasources,repositories}`,
  `presentation/{providers,screens,widgets}`, and a `feature.dart` barrel.
- `domain/` and `data/` are byte-identical to the `bloc` brick, so swapping the
  state extension only replaces `presentation/`.
- `notes_providers.dart` resolves `NotesRepository` from the Registry through
  `registryProvider` and exposes one provider per use case; an application can
  register its own repository without editing the sample.
- `NotesController` is an `AsyncNotifier` seeded from the domain stream, so a mutation
  is confirmed by the list coming back rather than by an optimistic write, and a
  rejected draft surfaces as an `AsyncError` carrying a `Failure`.
- `NotesPage` reads providers directly; no widget-level provider wrapper.
- New generated-app tests under `test/features/notes/`.

## 0.1.0

- Initial release.
