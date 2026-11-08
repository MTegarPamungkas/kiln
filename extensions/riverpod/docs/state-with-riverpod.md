# State with Riverpod

A feature is `domain/` + `data/` + `presentation/`, and everything
Riverpod-specific lives in `presentation/providers/`. `registryProvider` is
populated by the app wrapper, so a feature reads its contracts there:

```dart
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final registry = ref.watch(registryProvider);
  return registry.readOrNull<NotesRepository>() ??
      NotesRepositoryImpl(InMemoryNotesDatasource());
});

/// One provider per use case, so tests can override a single action.
final watchNotesProvider = Provider<WatchNotes>(
  (ref) => WatchNotes(ref.watch(notesRepositoryProvider)),
);
```

A service contract with no feature wrapper is read generically through
`kilnProvider<T>()`:

```dart
final profileProvider = FutureProvider<Profile>((ref) async {
  final client = ref.watch(kilnProvider<HttpClient>());
  final response = await client.get(Uri.parse('/profile'));
  return Profile.fromJson(response.data);
});
```

The screen is driven by an `AsyncNotifier`: `build` hands back the first value
of the domain stream and keeps listening, so the stream stays the single source
of truth and only a rejected mutation is assigned by hand:

```dart
final class NotesController extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final first = Completer<List<Note>>();
    final subscription = ref.watch(watchNotesProvider).call().listen((items) {
      if (!first.isCompleted) {
        first.complete(items);
        return;
      }
      state = AsyncData<List<Note>>(items);
    });
    ref.onDispose(subscription.cancel);
    return first.future;
  }

  Future<void> add(String body) async {
    final result = await ref.read(addNoteProvider).call(body);
    final failure = result.failureOrNull;
    if (failure != null) {
      state = AsyncError<List<Note>>(failure, StackTrace.current);
    }
  }
}

final notesControllerProvider =
    AsyncNotifierProvider<NotesController, List<Note>>(NotesController.new);
```

Use the `ProviderScope` from the app wrapper; `testProviderContainer(registry)`
in `core/riverpod/provider_overrides.dart` builds a container with a fake
Registry for tests.

`domain/` and `data/` of the sample feature are byte-identical to the `bloc`
brick, which is what makes swapping state management cheap: only
`presentation/` is rewritten.
