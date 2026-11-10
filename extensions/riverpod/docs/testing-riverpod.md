# Testing Riverpod features

Riverpod features read contracts through `kilnProvider<T>()`, which resolves
from the injected `registryProvider`. Tests override the registry, not the
network.

## Container helper

```dart
final registry = createTestRegistry(
  remoteDatabase: FakeRemoteDatabase(),
);
final container = testProviderContainer(registry);
addTearDown(container.dispose);

final client = container.read(kilnProvider<HttpClient>());
```

`testProviderContainer` overrides `registryProvider` with the test Registry. The
same `Provider` instance is returned for each type, so `ref.watch` shares one
provider node.

## Test a feature notifier

```dart
final container = ProviderContainer(
  overrides: [
    registryProvider.overrideWithValue(registry),
    notesRepositoryProvider.overrideWithValue(repository),
  ],
);
addTearDown(container.dispose);

final notes = await container.read(notesControllerProvider.future);
expect(notes, hasLength(1));

await container.read(notesControllerProvider.notifier).add('Second');
expect(container.read(notesControllerProvider).valueOrNull, hasLength(2));
```

Prefer overriding the feature's repository provider over mocking Riverpod
internals. Assert `AsyncValue` data/error/loading through `async_value_x.dart`
helpers, and assert that failures preserve the original `Failure`.

## Widget test

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [registryProvider.overrideWithValue(registry)],
    child: const NotesPage(),
  ),
);
```

When the generated app wrapper installs `ProviderScope`, pass the test registry
through its override. Use `pumpUntil` for async state transitions.

## Common mistakes

- Creating a `ProviderContainer` without disposing it leaks listeners.
- Using `container.read` for reactive widgets instead of `ref.watch`; widgets
  will not rebuild.
- Overriding `kilnProvider<T>()` itself; override `registryProvider` or the
  feature repository instead.
- Testing only the success path; assert loading, empty, error, and retry.
