# Migrating Riverpod to Bloc

`riverpod` and `bloc` are mutually exclusive; the contracts and the Registry are
unaffected, only the state layer changes. The full step-by-step walkthrough lives
in
[docs/guides/migrate-bloc-to-riverpod.md](../../../docs/guides/migrate-bloc-to-riverpod.md).

Short version: `kiln remove riverpod --yes`, `kiln add bloc`, move each
provider/Notifier into a Cubit/Bloc, swap `ConsumerWidget`/`ref.watch` for
`BlocBuilder`/`BlocListener`, and update your tests.
