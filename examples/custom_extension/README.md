# Custom extension

`demo/` is a complete extension project scaffolded with `kiln ext new` from the
`extension_template` brick. It shows the full authoring workflow: manifest,
brick, rendered module, failure mapping, tests, and docs.

## Layout

| Path | Purpose |
| --- | --- |
| `demo/extension.yaml` | Manifest: id `demo`, category `tooling`, tier `community`, provides `demo` |
| `demo/brick/` | Files rendered into the user project |
| `demo/brick/__brick__/lib/extensions/demo/` | `DemoModule`, `DemoConfig`, and failure mapper |
| `demo/docs/` | Extension documentation |
| `demo/test/` | Manifest, render, and rendered-output analyze tests |

The brick registers a `DemoConfig` singleton through `DemoModule`; application
code reads it from the `Registry` like any other capability.

## Create another extension

From a Kiln checkout:

```bash
dart run packages/kiln_cli/bin/kiln.dart ext new my_extension \
  --name "My extension" \
  --category tooling \
  --provides my_capability
```

Add `--with-hooks` or `--with-native-patch` when the extension needs Mason
hooks or platform file patches.

## Verify

Run inside `demo/`:

```bash
dart test
```

The tests validate the manifest, render the brick into a temporary project, and
run `flutter analyze` over the rendered output, so the example is the reference
for template changes.
