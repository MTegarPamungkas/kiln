# Migrating state management (bloc ⇄ riverpod)

`bloc` and `riverpod` are both exclusive in the `state` category, so only one can
be installed at a time. The contracts and the Registry are unaffected — only the
state layer changes. In a feature that follows the layer rules the swap is
confined to `presentation/`: `domain/` and `data/` are byte-identical between
the two bricks, so they stay untouched.

## Before you start

State management reaches `lib/main.dart`, the `lib/app/` composition files, and
the `presentation/` folder of every feature, so do the swap early in a project,
or when there is time to revisit every feature and test.

## bloc → riverpod

1. `kiln remove bloc --yes` (make sure the generated state files were not hand-edited).
2. `kiln add riverpod`.
3. Rewrite `lib/features/<feature>/presentation/` only: the Bloc with its events
   and state becomes a `StreamNotifier` or `AsyncNotifier` plus one provider per
   use case.
4. Replace `BlocBuilder`/`BlocListener` with `Consumer`/`ConsumerWidget` and
   `ref.watch`.
5. Replace `feature.dart`. The Bloc version reads the Registry and builds the
   bloc; the Riverpod version is an export-only barrel, because composition
   lives in the providers.
6. Leave `domain/` and `data/` exactly as they are.
7. Point tests at `testProviderContainer(registry)` from
   `lib/core/riverpod/provider_overrides.dart`; replace bloc expectations with
   `AsyncValue` ones.

## riverpod → bloc

1. `kiln remove riverpod --yes`.
2. `kiln add bloc`.
3. Rewrite `lib/features/<feature>/presentation/` only: the
   `StreamNotifier`/`AsyncNotifier` and its providers become a Bloc with one
   event per action.
4. Replace `ConsumerWidget`/`ref.watch` with `BlocBuilder`/`BlocListener`, and
   let the screen create the bloc through `BlocProvider`.
5. Replace `feature.dart` with the version that reads the Registry and builds
   the bloc.
6. Leave `domain/` and `data/` exactly as they are.
7. Point tests at the bloc itself: drive it with `add(...)` and await its
   `stream`, as the generated `notes_bloc_test.dart` does.

## Finish

Rebuild the app composition — `lib/app/bloc_providers.dart` or
`lib/app/provider_root.dart` — then run `kiln doctor` and the full
`flutter test` suite either way.
