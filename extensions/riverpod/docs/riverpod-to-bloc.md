# Migrating Riverpod to Bloc

The two state extensions are exclusive. General steps:

1. Move providers/Notifiers to Cubit/Bloc.
2. Replace `ConsumerWidget` with `BlocBuilder`.
3. Keep the contracts and the Registry; only the state layer changes.
4. `kiln remove riverpod`, then `kiln add bloc`.

Do the migration at the start of a project or when there is time to adjust the
features.
