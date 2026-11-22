# Changelog

## 0.1.1

- Support the Android core_library_desugaring manifest flag, using the existing
  shared native-patch ownership and reversible Gradle patch.

- Marked client string prompts accept env:NAME build-variable references and
  expose escaped Dart expressions through derived template variables.

- Use OS-backed project locks with async-context reentrancy and automatic
  process-exit recovery. Never take over a live operation based on file age.
- Exclude the project lock from staged copies.

- `ExtensionInstaller.configure` stages configuration changes across installed
  extensions in one transaction, verifies once, and rolls back the entire
  batch on failure. It preserves versions and refuses edited managed files.
- Transactions, snapshots, rollback, and migrations reject absolute paths,
  traversal, and symlink escapes before writing.
- Upgrades are staged and published as one verified transaction, with
  collision-safe defaults and explicit `force` overrides.
- The lockfile records dependencies, dev dependencies, and `flutter generate`
  only when Kiln added or changed them, so remove preserves user edits.

## 0.1.0

- Initial release.
