# Changelog

## 0.1.1

- Add `SecureStorageSupport` and report platform/device availability through
  `SupportRegistry`.
- `ready()` records an `unavailable` support state instead of failing
  bootstrap when the secure store cannot be prepared.

## 0.1.0

- Initial secure storage, token store, namespace, first-run wipe, and health
  check.
