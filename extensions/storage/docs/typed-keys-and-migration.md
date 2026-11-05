# Typed keys and migration

```dart
final notificationsEnabled = StorageKey<bool>(
  name: 'notifications_enabled',
  encode: (value) => value,
  decode: (value) => value as bool,
  defaultValue: true,
);
```

`StorageMigrator` stores the schema version in the `schema_version` key and runs
the migration steps at start. Add new steps without removing old ones.
