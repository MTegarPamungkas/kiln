# Architecture

This project is organised by feature, and each feature is organised by layer.
The rules below are the whole point of the layout: they are what keeps a feature
readable after six months and many contributors.

## Folder map

```text
lib/
  app/                      composition root only — registry scope, MaterialApp
                            seams, wrappers, error screen
  core/
    architecture/           UseCase contracts shared by every feature
    error/                  Failure presentation and the global handler
    l10n/                   text seam filled by the l10n extension
    theme/                  theme seam filled by the theme extension
    <extension>/            foundation installed by a state extension
  features/
    <feature>/
      domain/               pure Dart, no Flutter, no plugin
        entities/           business objects
        repositories/       contracts (interfaces) the feature depends on
        usecases/           one callable class per action
      data/                 implements domain
        models/             transport/storage shapes (dto, mappers)
        datasources/        the only place that touches a database or an API
        repositories/       repository implementations
      presentation/         reads domain, never data
        bloc/               Bloc events, states, and the bloc itself
        providers/          Riverpod providers and notifiers
        screens/            routes and pages
        widgets/            reusable widgets
      feature.dart          barrel: the only file allowed to know all three layers
    home/                   starting feature — replace it with your own
  extensions/               code installed by kiln, including extensions.g.dart
```

`test/` mirrors `lib/` one for one: `lib/features/notes/domain/...` is tested in
`test/features/notes/domain/...`.

## The dependency rule

Arrows point inward. Nothing in `domain/` may import anything from `data/`,
`presentation/`, `extensions/`, or a plugin package.

```text
presentation  ->  domain  <-  data
      `------------ feature.dart ------------'
```

- `domain/` answers "what does this feature mean". Pure Dart, trivially unit
  testable, no `BuildContext`, no `Registry`.
- `data/` answers "where does it come from". Swapping a local store for a
  backend extension changes this folder only.
- `presentation/` answers "how does the user drive it". Widgets, blocs, and
  providers; it calls use cases and never a repository directly.
- `feature.dart` is the composition point. Wiring a feature to a real backend
  means editing one file.

## Why the folders, not a DI package

Kiln apps resolve services from the `Registry` installed by the extensions.
Features reach it through the seam their state extension provides:

```dart
// Both state extensions resolve the contract in one place, feature.dart:
NotesRepository notesRepository(Registry registry) {
  return registry.readOrNull<NotesRepository>() ??
      NotesRepositoryImpl(InMemoryNotesDatasource());
}

// Bloc: the composition function builds the bloc from the repository.
NotesBloc createNotesBloc(Registry registry) {
  final repository = notesRepository(registry);
  return NotesBloc(addNote: AddNote(repository), watchNotes: WatchNotes(repository));
}

// Riverpod: a provider delegates to the same function, so the graph stays one
// line and the layer rule holds.
final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => notesRepository(ref.watch(registryProvider)),
);
```

This is why the sample keeps the Registry read in `feature.dart` rather than in
`presentation/`: a provider or a bloc that imported `data/` itself would be a
layer violation.

## Checking the rules

`kiln doctor` reads `lib/features/**` and reports every import that breaks the
dependency rule above: an outward layer hop (`domain` importing `data` or
`presentation`, `presentation` importing `data`), Flutter reaching into
`domain`, or one feature reaching into another feature's folders instead of its
`feature.dart`. They are warnings, so an existing project keeps building while
you clean it up.

```bash
kiln doctor
```

`packages/kiln_lints` ships the same ideas as analyzer rules
(`no_cross_extension_import`, `prefer_contract_over_impl`,
`no_plugin_in_features`). It is optional and is not enabled here: Dart has
deprecated the legacy `analyzer.plugins` mechanism that `custom_lint` uses, so
`flutter analyze` would only warn about the plugin without running the rules.

## Adding a feature

```bash
mkdir -p lib/features/orders/domain/entities \
         lib/features/orders/domain/repositories \
         lib/features/orders/domain/usecases \
         lib/features/orders/data/models \
         lib/features/orders/data/datasources \
         lib/features/orders/data/repositories \
         lib/features/orders/presentation/screens \
         lib/features/orders/presentation/widgets
```

These are literal paths on purpose: brace shorthand such as `{entities,repositories}`
is a bash feature, and PowerShell or `cmd` would create one directory actually
named `{entities,repositories}`.

Then, in order:

1. Write the entity and the repository contract in `domain/`.
2. Write one use-case class per action, implementing `UseCase`,
   `NoParamsUseCase`, or `StreamUseCase` from `lib/core/architecture/`.
3. Implement the contract in `data/`, mapping to and from a model.
4. Build the screen in `presentation/` and drive it with the state management
   extension you installed.
5. Wire the three layers in `feature.dart`.
6. Mirror every folder under `test/`.

Keep a feature in its own folder. If two features need the same code, either it
belongs in `lib/core/` (shared contract) or one feature owns it and the other
calls that feature's use case.
