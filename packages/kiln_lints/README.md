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

## Windows notes

`custom_lint` 0.8.1 fails to load a path-dependency plugin when the project path
contains spaces. Run the project from a path without spaces, or wait for the
upstream fix, if you use the plugin through a local path.
