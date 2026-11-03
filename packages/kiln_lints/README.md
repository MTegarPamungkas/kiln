# kiln_lints

Custom lint rules that keep Kiln applications on contracts.

| Rule | Default | Purpose |
| --- | --- | --- |
| `no_cross_extension_import` | on | Extensions never import each other. |
| `prefer_contract_over_impl` | on | Features/app code use `kiln_core` contracts from the Registry. |
| `no_plugin_in_features` | on | `lib/features` never imports a plugin directly. |
| `no_edit_generated_files` | off | Generated files must be regenerated, not edited. |
| `require_failure_handling` | on | Empty catch blocks in features are rejected. |

## Pasang

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

Jalankan:

```bash
dart run custom_lint
```

`no_edit_generated_files` bersifat opt-in:

```yaml
custom_lint:
  rules:
    - no_edit_generated_files
```

## Analyzer version

`custom_lint_builder` 0.8.1 masih memakai `analyzer ^8`, jadi package ini juga
memakai analyzer 8. Saat upstream merilis dukungan analyzer 14, `analyzer` dan
`custom_lint_builder` dinaikkan bersama tanpa mengubah API rule.

## Catatan Windows

`custom_lint` 0.8.1 gagal memuat plugin path dependency bila path proyek
mengandung spasi. Jalankan proyek dari path tanpa spasi, atau tunggu perbaikan
upstream, bila memakai plugin lewat path lokal.
