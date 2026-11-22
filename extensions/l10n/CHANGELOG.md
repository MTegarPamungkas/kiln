# Changelog

## 0.1.0

- Fence overlapping locale loads and keep a rejected locale from invalidating
  a valid restore. Verify persistence failure recovery.

- Initial release.
- The module disposes its locale controller, and a stored-locale read that
  finishes after shutdown no longer touches the disposed notifier.
