# kiln_lints

Custom lint rules that keep Kiln applications on contracts.

| Rule | Default | Purpose |
| --- | --- | --- |
| `no_cross_extension_import` | on | Extensions never import each other. |
| `prefer_contract_over_impl` | on | Features/app code use `kiln_core` contracts from the Registry. |
| `no_plugin_in_features` | on | `lib/features` never imports a plugin directly. |
| `no_edit_generated_files` | off | Generated files must be regenerated, not edited. |
| `require_failure_handling` | on | Empty catch blocks in features are rejected. |

## Install

```yaml
dev_dependencies:
  custom_lint: ^0.8.1
  kiln_lints: ^0.1.0
```

`analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

Run:

```bash
dart run custom_lint
```

`no_edit_generated_files` is opt-in:

```yaml
custom_lint:
  rules:
    - no_edit_generated_files
```

## Analyzer version

`custom_lint_builder` 0.8.1 still uses `analyzer ^8`, so this package uses
analyzer 8 as well. When upstream ships analyzer 14 support, `analyzer` and
`custom_lint_builder` are bumped together without changing the rule API.

## What actually enforces these rules

`flutter analyze` does not run these rules today. Dart has deprecated the
legacy `analyzer.plugins` entry point that `custom_lint` uses, so adding

```yaml
analyzer:
  plugins:
    - custom_lint
```

to a generated app makes `flutter analyze` report
`analysis_options_deprecated_plugins` and skip the rules entirely. Until
`custom_lint` moves to the new plugin system, the boundary that matters for the
feature layout is enforced by `kiln doctor`, which reads `lib/features/**`
directly through `layerViolations()` in `kiln_extension_sdk`:
`src/analysis/feature_layers.dart`. Treat this package as opt-in tooling that a
developer runs with `dart run custom_lint`, not as a build gate.

## Windows notes

`custom_lint` 0.8.1 fails to load a path-dependency plugin when the project path
contains spaces. Run the project from a path without spaces, or wait for the
upstream fix, if you use the plugin through a local path.
