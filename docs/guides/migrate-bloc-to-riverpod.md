# Migrating state management

`bloc` and `riverpod` are both exclusive in the `state` category, so only one of
them can be installed. Both are already available in the bundled catalog.

## Steps

1. `kiln remove bloc --yes` after making sure the state files were not edited.
2. `kiln add riverpod`.
3. Move features from Cubit/Bloc to providers/Notifier.
4. Switch state tests to the provider overrides from `kiln_testing`.
5. Run `kiln doctor` and the whole test suite.

Because state management touches `lib/bootstrap.dart` and `lib/app`, do the
migration early in the project or when there is time to adjust the features.
