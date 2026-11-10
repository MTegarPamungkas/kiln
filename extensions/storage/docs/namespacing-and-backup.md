# Namespacing and backup

`Storage` is a small key-value surface; the brick adds the pieces needed to keep
keys tidy and evolvable.

## Namespaces

`NamespacedStorage` prefixes every key:

```dart
final cache = NamespacedStorage(
  inner: registry.read<Storage>(),
  namespace: 'http_cache',
);

await cache.write('users', json);
```

`keys()` and `clear()` only operate on that prefix. Use one namespace per
extension or feature; do not change it after release or existing values become
invisible.

## Typed keys

`StorageKey<T>` keeps encode/decode logic next to the key:

```dart
const notificationsEnabled = StorageKey<bool>(
  name: 'notifications_enabled',
  encode: (value) => '$value',
  decode: (value) => value == 'true',
  defaultValue: true,
);
```

Use `JsonCodec` for objects. A malformed value should fall back to the default,
not crash startup.

## TTL values

`TtlStorage` wraps a `Storage` with an expiry timestamp and a `Clock`. Reads
delete expired values and return null. It is useful for cached ids and short-lived
flags, not for data that must survive indefinitely.

## Schema migrations

`StorageMigrator` stores a `schema_version` key and runs migration functions in
order:

```dart
await StorageMigrator(
  storage: storage,
  targetVersion: 2,
  migrations: [migrateToV1, migrateToV2],
).run();
```

Add new steps; do not delete old ones from the list. Migrations run before the
app reads feature data, so a failed migration should leave the app on defaults
and report a configuration/storage failure.

## Backup and secrets

SharedPreferences is not encrypted and may be included in platform backups.
Never store tokens, passwords, or private keys here; use `SecureStorage`.
For values that must not leave the device, document the platform backup policy
and consider clearing them on sign-out.
