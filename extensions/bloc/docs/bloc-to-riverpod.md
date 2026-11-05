# Migrating Bloc to Riverpod

`bloc` and `riverpod` are mutually exclusive; the contracts and the Registry are
unaffected, only the state layer changes. The full step-by-step walkthrough lives
in
[docs/guides/migrate-bloc-to-riverpod.md](../../../docs/guides/migrate-bloc-to-riverpod.md).

Short version: `kiln remove bloc --yes`, `kiln add riverpod`, move each Cubit/Bloc
into a provider/Notifier, swap `BlocBuilder` for `Consumer`/`ConsumerWidget`, and
update your tests. Do it early, or when there is time to revisit every feature.
