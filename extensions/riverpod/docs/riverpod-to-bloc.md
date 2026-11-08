# Migrating Riverpod to Bloc

`riverpod` and `bloc` are mutually exclusive; the contracts and the Registry are
unaffected, and in a layered feature only `presentation/` changes. The full
step-by-step walkthrough lives in
[docs/guides/migrate-bloc-to-riverpod.md](../../../docs/guides/migrate-bloc-to-riverpod.md).

Short version: `kiln remove riverpod --yes`, `kiln add bloc`, then per feature
replace `presentation/providers/` with `presentation/bloc/` — the
`StreamNotifier`/`AsyncNotifier` becomes a Bloc with an event per action, and
`ConsumerWidget`/`ref.watch` becomes `BlocBuilder`/`BlocListener`. Leave
`domain/` and `data/` untouched: they are byte-identical between the two bricks.
Replace `feature.dart`, the export-only barrel, with the one that wires the
repository and builds the bloc, and update your tests.
