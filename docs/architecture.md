# Kiln architecture

Kiln is a Dart monorepo that generates Flutter applications and maintains them
through extensions. A generated application only knows the contracts in
`kiln_core`; extensions never import each other.

## Packages

| Package | Responsibility |
| --- | --- |
| `kiln_core` | Contracts, `Failure`, `Result`, Registry, bootstrap, support probes, slots, session, privacy |
| `kiln_extension_sdk` | Manifest, resolver, Mason renderer, transactional installer, migrations |
| `kiln_cli` | `kiln` commands, prompts, reports, extension bundles |
| `kiln_testing` | Fakes per contract, contract suite, widget harness |
| `kiln_store` | Registry, checksums, trust, publish (registry phase) |
| `kiln_lints` | Custom lint rules for contracts, plugins, and generated files |

## Application runtime

1. `main.dart` runs `KilnBootstrap.run(modules: kilnModules())`.
2. Bootstrap assembles modules from the `requires`/`provides` capabilities.
3. Each module registers its services with the `Registry`.
4. Bootstrap calls `KilnModule.support(registry)` and records the result in
   `SupportRegistry`. Modules that are not supported skip `ready()`.
5. `KilnApp` exposes the Registry through `RegistryScope`.
6. `AppShell` reads the `AppThemeConfig`, `AppLocalizationsConfig`, and
   `RouterConfig` seams, plus the `app.wrappers` slot.
7. Features read contracts (`RegistryScope.read<HttpClient>()`), not
   implementations.

There is no static facade or global registry. Every service access goes through
the Registry that is passed explicitly.

## Support model

Manifest `platforms` decides whether a module is loaded. Runtime support decides
whether it can be used on the current device and configuration. Extensions
return `SupportInfo` from `support()`; the application reads
`SupportRegistry` when it needs to show information or choose a fallback.
Support probes must be cheap and must not prompt the user. Unsupported calls
return typed failures instead of crashing startup. See
[extensions/support-and-devices.md](extensions/support-and-devices.md).

## Extension model

An extension consists of:

- `extension.yaml` — the manifest: capabilities, prompts, slots, dependencies,
  native patches, compatibility.
- `brick/` — Mason templates rendered into the user's project.
- `test/` — extension-level manifest, render, and analyze tests.
- `README.md`, `CHANGELOG.md`, `docs/` — extension documentation.

Extensions communicate only through capabilities and slots. `http_retry`
depends on `http_client`/`http_pipeline`, not on the id `dio`.

## Transactional installation

`kiln add` runs the following pipeline:

1. Read `kiln.yaml` and `kiln.lock.yaml`.
2. The resolver selects capability providers, detects exclusive conflicts,
   unopened slots, and dependency cycles.
3. Render the brick into a temporary folder.
4. Apply the collision policy against the ownership hashes in the lockfile.
5. Compute native patches and the changes to `pubspec.yaml`/`extensions.g.dart`.
6. Write all changes in a single `Transaction` with a journal, backups, and
   rollback.
7. Verify `pub get` and `analyze` when enabled.

`kiln remove` only deletes files whose hash still matches the lockfile. Files
edited by the user are skipped unless `--force` is given.

## Error model

Contracts throw `Failure` with a stable `FailureCode`. Feature code can convert
it into `Result<T>` with `Result.guard`. `kiln_core` also ships `Result` as a
helper, not as a second contract.

The observable outcomes are specified in
[concepts/contract-behavior.md](concepts/contract-behavior.md): missing records,
pagination, combined filters, logout failure, and unsupported backends. A
provider that disagrees fails its `kiln_testing` contract suite.

## Dependencies

All dependencies use a caret to the newest release that the current toolchain
can resolve. Two exceptions are documented in `README.md`: `test` follows
Flutter's `test_api` pin, and `kiln_lints` follows `custom_lint_builder`.

See [folder-structure.md](folder-structure.md) for the complete target structure
and [roadmap.md](roadmap.md) for the phase order.
