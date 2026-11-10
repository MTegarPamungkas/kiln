# Changelog

## 0.1.1

- Transactions, snapshots, rollback, and migrations reject absolute paths,
  traversal, and symlink escapes before writing.
- Upgrades are staged and published as one verified transaction, with
  collision-safe defaults and explicit `force` overrides.
- The lockfile records dependencies, dev dependencies, and `flutter generate`
  only when Kiln added or changed them, so remove preserves user edits.

## 0.1.0

- Initial release.
