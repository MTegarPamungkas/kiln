# Changelog

## 0.1.1

- Gate verbs resolve their contract inside the guard, so a missing extension
  returns `Err(configurationMissing)` instead of throwing.
- `LifecycleController.dispose` now owns module shutdown, is idempotent, and
  disposes modules that fail during registration.

## 0.1.0

- Initial release.
