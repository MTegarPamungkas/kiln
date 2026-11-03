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
