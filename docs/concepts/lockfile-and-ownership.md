# Lockfile and ownership

`kiln.lock.yaml` records each extension's version, source, dependencies, files
with their SHA-256 hashes, native patches, and manual steps.

```yaml
lock_version: 2
core: "0.1.0"
extensions:
  dio:
    version: "0.2.0"
    source: "bundled"
    dependencies: ["dio"]
    files:
      "lib/extensions/dio/dio_module.dart": "sha256:..."
    patches: ["android.permission.INTERNET"]
    manual_steps: []
```

Rules:

- Files without a hash (old locks) are treated as coming from an unknown source.
- `kiln remove` only deletes files whose current hash matches the lockfile.
- Files edited by the user are skipped; `--force` deletes them.
- `kiln doctor` compares hashes and reports changed files.
- `extensions.g.dart` is owned by Kiln and synced from the lockfile.

## Editing installed code

| Code | How to work with it |
| --- | --- |
| Screens and business logic in `lib/features/` | Application code; build your features here. Some extensions also install sample features. |
| Installed extension files and shared helpers recorded in the lockfile | Editable source, but changes affect removal, repair, and upgrades. Check ownership with `kiln doctor`. |
| `lib/extensions/extensions.g.dart` | Generated wiring; regenerate with `kiln doctor --fix` instead of editing it. |
| `kiln.lock.yaml` and `.kiln/` | Installer metadata and rollback history; let the CLI manage them. |

For routine feature work, call Gate verbs instead of modifying a provider.
When provider customization is necessary, you can edit its installed source.
Kiln detects changes using the stored hashes; it does not merge your edits
into a newer template automatically.

Before an upgrade:

1. Save your edits in version control or another backup.
2. Run `kiln doctor` to identify modified managed files.
3. Run `kiln upgrade --dry-run` to inspect candidate versions. This preview does
   not render the upgrade or predict every file conflict.
4. Run `kiln upgrade` and review any conflicts. Use `--force` only when you
   intend to replace edited files, then reapply the customizations you need.
5. Review the diff and run your app's analyzer and tests.

`kiln remove` preserves modified files unless `--force` is given. Preserved
files can remain on disk after their extension is removed from the lockfile;
review them before reinstalling. `kiln repair` restores installed templates
and patches, so inspect its `--dry-run` output before using it on customized
code. Repair can overwrite customized non-ARB files without `--force`.
`kiln rollback` restores the last transaction's snapshots; use it before
making further edits to those files.
