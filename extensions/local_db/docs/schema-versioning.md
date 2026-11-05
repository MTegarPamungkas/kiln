# Schema versioning

`SchemaMigrator` keeps the current schema version in the `_schema` collection and,
on `run()`, applies only the migration steps that have not yet been applied, then
records the new version. Each step in `migrations` brings the store from index *n*
to *n+1*.

```dart
final migrator = SchemaMigrator(
  database: db,
  targetVersion: 2,
  migrations: <LocalDbMigration>[
    (db) async => createUsersTable(db), // 0 -> 1
    (db) async => addEmailColumn(db),   // 1 -> 2
  ],
);

await migrator.run(); // applies pending steps and records version 2
```

Rules:

- **Append, never rewrite.** Once a version ships, its steps are frozen; fix issues
  with a later step rather than editing history, or upgrades skip the work.
- **Target version drives it.** `run()` is a no-op when the stored version is
  already `>= targetVersion`, so it is safe on every launch.
- **Test upgrades.** Add a migration test that opens at the previous version and
  confirms data survives the bump.

`BackupExport` complements migrations: it exports selected collections to JSON and
restores them with `import`, so you can snapshot a database before a risky
migration and roll it back by hand if needed.
