# Schema versioning

`SchemaMigrator` stores the version in the `_schema` collection and runs the
migration steps that have not been applied yet. Add new steps in the next
position; do not change steps that have already been released.

`BackupExport` exports the selected collections to JSON and restores them
through `import`.
