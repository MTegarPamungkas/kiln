# Testing Bloc features

The Bloc brick installs a foundation, not a test framework. Test blocks the same
way as any Bloc: provide a fake repository, add events, and assert the emitted
states. The sample notes feature is the reference.

## Test the repository first

Keep domain/data tests independent of widgets:

```dart
test('createNote writes one row', () async {
  final database = FakeRemoteDatabase();
  final repository = NotesRepositoryImpl(database: database);

  await repository.createNote('Buy milk');

  expect((await database.query('notes')).single['title'], 'Buy milk');
});
```

`FakeRemoteDatabase` and `createTestRegistry` come from `kiln_testing`.

## Test a Bloc

The sample bloc takes use cases, not a repository:

```dart
test('loads notes', () async {
  final repository = FakeNotesRepository(<Note>[Note(id: '1', body: 'A')]);
  final bloc = NotesBloc(
    watchNotes: WatchNotes(repository),
    addNote: AddNote(repository),
    toggleNote: ToggleNote(repository),
    removeNote: RemoveNote(repository),
  );

  expect(bloc.state.isLoading, isTrue);
  await expectLater(
    bloc.stream,
    emits(
      isA<NotesState>().having((state) => state.notes, 'notes', hasLength(1)),
    ),
  );
  await bloc.close();
});
```

Adapt the event/state names to the generated sample. Test the success, empty,
failure, retry, and cancellation paths; assert the failure state carries the
`Failure` from the repository, not a string. `NotesState` exposes `problem`
(`Failure?`), `isLoading`, and `notes`.

## BaseBloc and AsyncBloc

- `runGuarded` converts a thrown `Failure` into `Err`; use it inside handlers.
- `reportResult` emits the failure state through the handler's `Emitter`.
- `AsyncBloc` already handles `AsyncLoad`, `AsyncRefresh`, and `AsyncRetry`; test
  the state sequence around a failing fetcher rather than duplicating it.

## Widget test

```dart
testWidgets('renders notes', (tester) async {
  final registry = createTestRegistry(remoteDatabase: FakeRemoteDatabase());
  registry.registerLazySingleton<NotesRepository>(
    () => notesRepository(registry),
  );
  await pumpApp(tester, const NotesPage(), registry: registry);
  await pumpUntil(tester, () => find.text('A').evaluate().isNotEmpty);
});
```

The Bloc app wrapper supplies `BlocProvider`; if the page reads a repository
from the Registry, register the feature contract before `pumpApp`.

## What not to test

- Do not assert private fields; assert emitted states and repository calls.
- Do not mock `Bloc.emit`; `BaseBloc` keeps emission in `Emitter`.
- Do not use a fake that bypasses failure mapping when testing error UI; the
  state must carry the mapped `Failure`.
