# Changelog

## 0.1.1

- Fence overlapping preference loads; an older completion cannot undo the
  latest restore. Regressions verify best-effort persistence and recovery.

- The module orders itself after storage, so the saved theme mode is
  restored instead of falling back to an in-memory controller.
- The module disposes its mode controller, and a stored-mode read that
  finishes after shutdown no longer touches the disposed notifier.

## 0.1.0

- Initial release.
