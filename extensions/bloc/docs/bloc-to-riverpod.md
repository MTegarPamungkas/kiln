# Migrating Bloc to Riverpod

The two state extensions are mutually exclusive. The general steps:

1. Move per-feature state into providers/Notifiers.
2. Replace `BlocBuilder` with `Consumer`/`ConsumerWidget`.
3. Keep the contracts and Registry; only the state layer changes.
4. Run `kiln remove bloc` then `kiln add riverpod`.

Because the change touches the application wrapper and tests, do it at the start
of the project or when there is time to adjust the features.
