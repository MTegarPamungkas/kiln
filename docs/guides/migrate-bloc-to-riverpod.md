# Migrating state management (bloc ⇄ riverpod)

`bloc` and `riverpod` are both exclusive in the `state` category, so only one can
be installed at a time. The contracts and the Registry are unaffected — only the
state layer changes.

## Before you start

State management reaches `lib/bootstrap.dart` and `lib/app`, so do the swap early
in a project, or when there is time to revisit every feature and test.

## bloc → riverpod

1. `kiln remove bloc --yes` (make sure the generated state files were not hand-edited).
2. `kiln add riverpod`.
3. Move each Cubit/Bloc class into a provider/Notifier.
4. Replace `BlocBuilder`/`BlocListener` with `Consumer`/`ConsumerWidget` and `ref.watch`.
5. Point tests at the provider overrides from `kiln_testing`.

## riverpod → bloc

1. `kiln remove riverpod --yes`.
2. `kiln add bloc`.
3. Move each provider/Notifier back into a Cubit/Bloc.
4. Replace `ConsumerWidget`/`ref.watch` with `BlocBuilder`/`BlocListener`.
5. Point tests at the bloc test harness.

## Finish

Run `kiln doctor` and the full `flutter test` suite either way.
