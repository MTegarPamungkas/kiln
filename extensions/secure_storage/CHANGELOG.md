# Changelog

## 0.2.0

- Expose `readAllSecure` and `clearSecure` gate verbs so the full
  `SecureStorage` contract is reachable as one-call `Result` calls.
- Map `delete` failures to `secure_storage.write_failed` instead of
  `secure_storage.read_failed`.

## 0.1.1

- Add `SecureStorageSupport` and report platform/device availability through
  `SupportRegistry`.
- `ready()` records an `unavailable` support state instead of failing
  bootstrap when the secure store cannot be prepared.

## 0.1.0

- Initial secure storage, token store, namespace, first-run wipe, and health
  check.
