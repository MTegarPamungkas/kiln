# Changelog

## 0.2.0

- Expose `hasValue`, `storageKeys`, and `clearValues` gate verbs so the full
  `Storage` contract is reachable as one-call `Result` calls.
- Map `delete` failures to `storage.write_failed` instead of
  `storage.read_failed`.
- `StorageKey.read` reports a corrupt stored value as a typed storage
  `Failure` instead of leaking a `FormatException`.

## 0.1.1

- Add `StorageSupport` and report platform availability through
  `SupportRegistry`.
- Record a failed schema migration as `unavailable` instead of failing
  bootstrap.

## 0.1.0

- SharedPreferences storage, typed keys, TTL, namespacing, and schema migration.
