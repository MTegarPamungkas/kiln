# Migrating Bloc to Riverpod

`bloc` and `riverpod` are mutually exclusive; the contracts and the Registry are
unaffected, and in a layered feature only `presentation/` changes. The full
step-by-step walkthrough lives in
[docs/guides/migrate-bloc-to-riverpod.md](../../../docs/guides/migrate-bloc-to-riverpod.md).

Short version: `kiln remove bloc --yes`, `kiln add riverpod`, then per feature
replace `presentation/bloc/` with `presentation/providers/` — the Bloc becomes a
`StreamNotifier` or `AsyncNotifier` plus its use-case providers, and
`BlocBuilder`/`BlocListener` become `ConsumerWidget` with `ref.watch`. Leave
`domain/` and `data/` untouched: they are byte-identical between the two bricks.
Replace `feature.dart`, which held the Bloc wiring, with the barrel the Riverpod
brick generates, and update your tests. Do it early, or when there is time to
revisit every feature.
