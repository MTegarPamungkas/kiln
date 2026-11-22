# kiln_core

Core contracts and runtime for Kiln applications.

Main contents:

- HTTP, storage, auth, platform, observability, and configuration contracts;
- `Gate`, `Failure`, `FailureCode`, and `Result<T>`;
- `Registry`, `KilnModule`, `ModuleGraph`, `KilnBootstrap`, `OrderedSlot`;
- `SupportInfo`, `SupportState`, `SupportRegistry`, and the
  `KilnModule.support` probe hook;
- `SessionController`, `ConsentController`, `PiiRedactor`, `Clock`,
  `Debouncer`.

This package does not depend on Flutter plugins. Applications and extensions may
only know about the contracts defined here.

```dart
final registry = await KilnBootstrap.run(modules: kilnModules());
final gate = registry.read<Gate>();
final result = await gate.httpGet(Uri.parse('https://api.example.com/items'));
result.fold(
  ok: (response) => print('HTTP ${response.statusCode}'),
  err: (failure) => print(failure.message),
);

final support = registry.read<SupportRegistry>();
if (support['biometric']?.isSupported ?? false) {
  // use the feature
}
```

Install an HTTP provider such as `dio` to use `httpGet`. Gate verbs return
`Result`, including when a service is missing. Direct getters and `use<T>()`
can throw; wrap custom operations with `gate.call(() => ...)`.

See the [Gate reference](../../docs/reference/gate.md),
[docs/architecture.md](../../docs/architecture.md), and
[docs/extensions/support-and-devices.md](../../docs/extensions/support-and-devices.md).
