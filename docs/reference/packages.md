# Packages

Kiln is a Dart workspace. Applications normally depend on `kiln_core`; the CLI
and extension authoring tools use the other packages. Each package has a
dedicated page generated from its README.

| Package | Responsibility | Depends on Flutter | Entry point |
| --- | --- | --- | --- |
| [`kiln_core`](../../packages/kiln_core/README.md) | Contracts, errors, registry, bootstrap, lifecycle, support, slots, session, privacy, utilities | No | `package:kiln_core/kiln_core.dart` |
| [`kiln_extension_sdk`](../../packages/kiln_extension_sdk/README.md) | Manifest, resolver, renderer, installer, transactions, migrations | No | `package:kiln_extension_sdk/kiln_extension_sdk.dart` |
| [`kiln_cli`](../../packages/kiln_cli/README.md) | `kiln` command line, prompts, reports, bundled catalog | No | `package:kiln_cli/kiln_cli.dart` |
| [`kiln_store`](../../packages/kiln_store/README.md) | Registry client, checksums, trust, cache, publish | No | `package:kiln_store/kiln_store.dart` |
| [`kiln_testing`](../../packages/kiln_testing/README.md) | Fakes, contract suites, widget/async/golden harness | Yes | `package:kiln_testing/kiln_testing.dart` |
| [`kiln_lints`](../../packages/kiln_lints/README.md) | Custom `custom_lint` rules for Kiln boundaries | No | plugin package |

## Dependency direction

```text
application
  └─ kiln_core
       └─ (no extension imports)

extension
  └─ kiln_core
       └─ optional kiln_testing (tests only)

kiln_cli
  ├─ kiln_extension_sdk
  └─ kiln_store

kiln_extension_sdk
  └─ kiln_core (contracts used by generated code)
```

`kiln_core` never depends on an extension, a Flutter plugin, or the installer.
Extensions never import each other. The CLI composes the SDK and store packages.

## Versioning

The workspace packages share the `0.1.x` line. `kiln_cli` advertises
`kilnVersion`/`kilnCoreVersion` and must match the package versions. Extension
manifests declare compatibility with a Kiln range, for example
`>=0.1.0 <0.2.0`.

`tool/check_versions.dart` checks package versions, CHANGELOG headings, CLI
constants, and intra-workspace constraints. `tool/check_drift.dart` checks
third-party constraints against pub.dev on a schedule.

## Which package to use

- Building an app: `kiln_core`, plus the generated project dependencies.
- Writing an extension: `kiln_core`, `kiln_testing`, and the generated brick.
- Adding CLI behavior: `kiln_cli`, usually through `kiln_extension_sdk`.
- Building a registry or publisher: `kiln_store`.
- Enforcing architecture in CI: `kiln_lints` (opt-in) and `kiln doctor`.
- Testing a provider: `kiln_testing` contract suites.

## Source and tests

```bash
cd packages/kiln_core && dart test
cd packages/kiln_extension_sdk && dart test
cd packages/kiln_store && dart test
cd packages/kiln_cli && dart test
cd packages/kiln_testing && flutter test
cd packages/kiln_lints && dart test
```

Package README pages contain the detailed API tour, examples, and caveats for
each package.
