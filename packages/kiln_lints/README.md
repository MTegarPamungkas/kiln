# kiln_lints

Analyzer plugin rules that keep Kiln applications on contracts.

| Rule | Default | Purpose |
| --- | --- | --- |
| `no_cross_extension_import` | on | Extensions never import each other. |
| `prefer_contract_over_impl` | on | Features/app code use `kiln_core` contracts from the Registry. |
| `no_plugin_in_features` | on | `lib/features` never imports a plugin directly. |
| `no_edit_generated_files` | off | Generated files must be regenerated, not edited. |
| `require_failure_handling` | on | Empty catch blocks in features are rejected. |

## Install

Add `kiln_lints` under the top-level `plugins:` section in
`analysis_options.yaml` (Dart 3.10+ / `analysis_server_plugin`):

```yaml
plugins:
  kiln_lints:
    path: ../packages/kiln_lints
```

Then run `dart analyze` or `flutter analyze` as usual.

`no_edit_generated_files` is registered as an opt-in lint rule and can be
enabled per project under `plugins.kiln_lints.diagnostics`:

```yaml
plugins:
  kiln_lints:
    path: ../packages/kiln_lints
    diagnostics:
      no_edit_generated_files: true
```

## Analyzer version

`kiln_lints` uses Dart's official `analysis_server_plugin` (`^0.3.26`) on
`analyzer ^14.7.0`, so it resolves in the same workspace as the rest of the
Kiln monorepo and runs directly inside `dart analyze` and `flutter analyze`.
