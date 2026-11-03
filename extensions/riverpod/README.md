# riverpod

Kiln state management based on `flutter_riverpod`.

This extension is exclusive in the `state` category, provides `state_riverpod`, and
adds `ProviderScope` through the `app.wrappers` slot. The Registry is overridden to
providers, so features can read contracts with:

```dart
final client = ref.watch(kilnProvider<HttpClient>());
```

Brick contents:

- `kiln_providers.dart` — `registryProvider` and `kilnProvider<T>()`.
- `provider_overrides.dart` — Registry overrides for tests.
- `async_value_x.dart` — concise failure/data access.
- `session_notifier.dart` — wraps `SessionController`.
- counter feature example.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
