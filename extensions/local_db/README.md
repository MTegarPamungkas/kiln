# local_db

Implementation of `LocalDatabase` from `kiln_core` on top of Sembast.

Features:

- key-value document collections,
- `where`, `orderBy`, `limit`, and `offset` queries,
- collection change streams,
- atomic transactions,
- typed collections with `fromJson`/`toJson`,
- JSON export/import backup,
- sync queue for RemoteDatabase,
- schema migrations,
- optional AES-GCM encryption with keys from SecureStorage.

## Gate

```dart
final record = await gate.localGet('notes', '1');   // Result<Map<String, Object?>?>
await gate.localPut('notes', '1', {'title': 'Hi'}); // Result<void>
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
