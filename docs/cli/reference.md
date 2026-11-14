# CLI reference

The `kiln` command creates projects, installs extensions transactionally, and
maintains the lockfile, native patches, codegen, registry cache, and docs
catalog.

## Global flags

| Flag | Meaning |
| --- | --- |
| `--verbose` | More diagnostic output |
| `--quiet` | Only errors and explicit results |
| `--json` | Machine-readable output on commands that support it |
| `--yes`, `-y` | Non-interactive; accept defaults/confirmations |
| `--dry-run` | Plan changes without writing where supported |
| `--answer name=value` | Prompt answer where supported; use `extension.name=value` when names collide |

Exit codes are stable; see [exit codes](#exit-codes).

## Commands

| Command | Purpose |
| --- | --- |
| `kiln create <name>` | Create a project from `app_basic`; `l10n` is installed automatically |
| `kiln add <extension...>` | Install one or more extensions transactionally |
| `kiln remove <extension>` | Remove an extension; edited files are skipped |
| `kiln repair [extension...]` | Restore generated files and `extensions.g.dart` |
| `kiln list` | Installed and available extensions |
| `kiln info <extension>` | Full manifest of one extension |
| `kiln graph` | Capability graph as text or Mermaid |
| `kiln doctor` | Check hashes, codegen, journal, dependencies, manifests, platforms, feature layers, capability coverage, and core resolution |
| `kiln upgrade` | Upgrade from the registry or the bundled catalog |
| `kiln rollback` | Undo the last or an interrupted transaction |
| `kiln config` | Registry, mirror, offline mode |
| `kiln cache` | Inspect or clear the registry cache |
| `kiln store` | `search`, `info`, and `install` from a registry |
| `kiln completion <shell>` | Print a bash/zsh/fish completion script |
| `kiln ext ...` | `new`, `validate`, `test`, `pack`, `publish` |
| `kiln version` | CLI and `kiln_core` versions |

## create

```bash
kiln create my_app
kiln create my_app --with dio --answer base_url=https://api.example.com
kiln create starter --template app --state bloc
```

| Flag | Meaning |
| --- | --- |
| `--state none\|bloc\|riverpod` | State layer to install (default `none`) |
| `--template minimal\|app` | Minimal root or starter page (default `minimal`) |
| `--org` | Organization for `flutter create` (default `com.example`) |
| `--description` | Project description |
| `--platforms` | Comma-separated platforms (default `android,ios,web`) |
| `--with` | Extensions to install immediately |
| `--answer` | Prompt answer, repeatable |
| `--core-path` | Use a local `kiln_core` checkout |
| `--core-git` | Resolve `kiln_core`/`kiln_testing` from a Git repository |
| `--core-ref` | Branch, tag, or commit with `--core-git` |
| `--output` | Parent directory (default `.`) |
| `--force` | Write into an existing target |
| `--[no-]pub` | Run `flutter pub get` (default on) |

`--core-path` and `--core-git` are mutually exclusive. Without either, the CLI
uses the public Kiln repository baked into the build. `l10n` is always installed
because the app shell needs the localization seam.

## add

```bash
kiln add dio --answer base_url=https://api.example.com
kiln add http_cache http_retry --yes
kiln add rest_auth --dry-run --json
```

`add` resolves capabilities, renders bricks into a temporary directory, plans
collisions against the lockfile, writes all changes through one transaction, and
optionally runs `pub get`/`analyze`.

| Flag | Meaning |
| --- | --- |
| `--answer` | Prompt answer; repeatable |
| `--dry-run` | Show the plan without writing |
| `--force` | Overwrite files that would otherwise conflict |
| `--no-verify` | Skip the `pub get`/`analyze` verification |
| `--json` | Machine-readable plan/result |
| `--yes` | Non-interactive prompts |

Hooks run only when hooks are enabled by the extension and the trust decision
allows/confirms them.

## remove

```bash
kiln remove dio --yes
kiln remove dio --dry-run
kiln remove dio --force
```

`remove` deletes only files whose hash still matches the lockfile. Edited files
are skipped unless `--force` is given. Dependencies added by Kiln and no longer
needed are removed; user-owned dependencies are preserved. Native patches and
codegen are reverted.

Flags: `--dry-run`, `--force`, `--json`, `--yes`.

## repair

```bash
kiln repair
kiln repair dio --dry-run
kiln repair --force
```

Restores generated files, `extensions.g.dart`, and native patches from the
installed extension versions. ARB localization files are protected unless
`--force` is used. Flags: `--dry-run`, `--force`, `--yes`.

## list, info, graph, doctor

```bash
kiln list
kiln list --installed
kiln list --available --json

kiln info dio
kiln graph --format mermaid
kiln doctor
kiln doctor --fix
```

| Command | Notes |
| --- | --- |
| `list` | `--installed`, `--available`, `--json` |
| `info` | Full manifest; `--json` |
| `graph` | `--format text\|mermaid`, `--json` |
| `doctor` | `--fix` applies safe repairs; `--json` |

`doctor` checks file hashes, codegen drift, interrupted journals, dependencies,
manifest and platform compatibility, feature-layer rules, backend capability
coverage (feature code that references a capability no installed extension
provides, for example `CloudFunctions` after a backend swap), and how
`kiln_core` resolves. It only sees manifests and the project; device support is
a runtime probe.

## upgrade

```bash
kiln upgrade
kiln upgrade --all --no-verify --yes
kiln upgrade --dry-run --json
```

| Flag | Meaning |
| --- | --- |
| `--all` | Consider every installed extension |
| `--dry-run` | Print candidates without applying |
| `--force` | Replace edited files and take conflicts |
| `--no-verify` | Skip `pub get`/`analyze` |
| `--run-hooks` | Run extension hooks when the trust policy allows |
| `--answer` | Answer new required prompts |
| `--yes` | Non-interactive confirmations |
| `--json` | Machine-readable candidates/result |

Without a configured registry, `upgrade` uses the bundled catalog. With a
registry, it selects a compatible version and loads migrations from the archive.
It resolves prompts before touching the project, stages the whole upgrade, and
publishes one transaction. A failed verification rolls back the managed files and
lockfile. Bundled Dart catalogs do not embed migration files; every bundled
extension currently ships none.

## rollback

```bash
kiln rollback
kiln rollback --list
kiln rollback --json
```

Reverses the newest committed or interrupted transaction. `--list` shows
available backups/journals. Rollback validates every path before restoring.

## config

```bash
kiln config --registry="$(pwd)/registry"
kiln config --mirror=https://mirror.example.dev/kiln
kiln config --offline
kiln config --global
```

Flags: `--registry`, `--mirror`, `--offline`, `--global`, `--json`. Project
configuration is written to `kiln.yaml`; `--global` writes the user config.
Registry URLs may be HTTP(S), `file:`, or local paths.

## cache

```bash
kiln cache
kiln cache clean
kiln cache --json
```

Lists the registry cache or deletes it. The cache is scoped by registry identity
and verifies archive checksums before extraction.

## store

```bash
kiln store search dio
kiln store info dio
kiln store install dio --yes
kiln store install dio --version 0.1.1 --force
```

| Subcommand | Purpose |
| --- | --- |
| `search [query]` | Search the cached/registry index |
| `info <id>` | Show available versions and metadata |
| `install <id>` | Download, verify checksum/trust, then install |

Flags: `--version`, `--dry-run`, `--force`, `--no-verify`, `--run-hooks`,
`--yes`, `--json`.

`install` refuses an archive whose SHA-256 does not match the selected version.

## completion

```bash
kiln completion bash
kiln completion zsh
kiln completion fish
```

Prints the completion script to stdout. Source it from your shell profile.

## ext

```bash
kiln ext new my_extension --name "My extension" --category tooling \
  --provides my_capability
kiln ext validate extensions/my_extension
kiln ext test extensions/my_extension
kiln ext pack extensions/my_extension --output dist
kiln ext publish extensions/my_extension --registry="$(pwd)/registry"
```

| Subcommand | Flags |
| --- | --- |
| `new` | `--name`, `--category`, `--provides`, `--requires`, `--output`, `--with-hooks`, `--with-native-patch` |
| `validate` | `--json` |
| `test` | `--json` |
| `pack` | `--output`, `--json` |
| `publish` | `--registry`, `--archive-base-url`, `--dry-run`, `--force`, `--json` |

`ext new` renders the extension template. `validate` checks the manifest and
brick. `test` runs manifest/render/analyze tests. `pack` writes a deterministic
`.tar.gz`. `publish` validates, writes the archive, and updates the registry
index.

## version

```bash
kiln version
kiln version --json
```

Reports the CLI version and the `kiln_core` version it expects.

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success |
| 64 | Invalid arguments |
| 65 | Project/manifest/prompt problem |
| 66 | Dependency/file conflict |
| 69 | Network failure |
| 70 | Verification failed |
| 71 | Internal error |

## Registry and offline mode

```bash
kiln config --registry="$(pwd)/registry"
kiln store search
kiln store info connectivity
kiln store install connectivity --yes
kiln upgrade --yes
kiln ext publish extensions/connectivity --registry="$(pwd)/registry"
```

- `store install` downloads the archive, verifies its SHA-256, checks the trust
  policy, then installs through the installer transaction.
- `upgrade` selects a compatible version, resolves prompts before writes, runs
  registry migrations, and publishes one transaction.
- `ext publish` and `tool/registry.dart` write `index.json` plus
  `archives/<id>-<version>.tgz`.
- `kiln cache clean` deletes cached indexes and archives. Offline mode uses only
  what remains and requires matching cached metadata for an archive.

## Runtime support

Device-level support (camera, biometrics, keyrings, plugin initialization,
backend configuration) is probed at runtime by `KilnModule.support()` and
exposed through `SupportRegistry`. See
[../extensions/support-and-devices.md](../extensions/support-and-devices.md).

## Limitations

- Publishing to an HTTP registry is not supported yet; publish to a local folder
  and push it with Git or a release.
- Native Android/iOS product flavors are not generated by the flavors extension.
- `kiln_lints` is waiting for `custom_lint` to support analyzer 14.
- Bundled Dart catalogs do not embed migration files; registry upgrades do.
