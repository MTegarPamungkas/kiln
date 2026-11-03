# kiln_core

Core contracts and runtime for Kiln applications.

Main contents:

- HTTP, storage, auth, platform, observability, and configuration contracts;
- `Failure`, `FailureCode`, and `Result<T>`;
- `Registry`, `KilnModule`, `ModuleGraph`, `KilnBootstrap`, `OrderedSlot`;
- `SessionController`, `ConsentController`, `PiiRedactor`, `Clock`,
  `Debouncer`.

This package does not depend on Flutter plugins. Applications and extensions may
only know about the contracts defined here.

```dart
final registry = await KilnBootstrap.run(modules: kilnModules());
final client = registry.read<HttpClient>();
```

See [docs/architecture.md](../../docs/architecture.md).
