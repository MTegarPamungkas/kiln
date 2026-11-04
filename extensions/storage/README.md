# storage

Implementation of `Storage` from `kiln_core` on top of `shared_preferences`.

This extension provides the `storage` capability. Application code reads the contract
from the Registry; there is no static facade.

Brick contents:

- a `SharedPreferencesAsync` gateway that can be faked,
- `SharedPreferencesStorage` with a per-app prefix,
- typed `StorageKey<T>`,
- `TtlStorage` using a `Clock`,
- `NamespacedStorage` for other owners such as `http_cache`,
- `StorageMigrator` for key schema versions.

## Gate

```dart
final value = await gate.readValue('theme');   // Result<String?>
await gate.writeValue('theme', 'dark');        // Result<void>
await gate.deleteValue('theme');               // Result<void>
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
