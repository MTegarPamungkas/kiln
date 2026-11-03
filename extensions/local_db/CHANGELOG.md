# Changelog

## 0.1.1

- Add `LocalDatabaseSupport` and report path/storage availability through
  `SupportRegistry`.
- Keep the database lazily opened while still returning an informational
  unsupported state when the platform has no writable storage.

## 0.1.0

- Sembast LocalDatabase with queries, watch, transactions, typed collections,
  backup, sync queue, schema migration, and optional encryption.
