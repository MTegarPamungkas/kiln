# Kiln registry

A local registry generated from the `extensions/` folder by:

```bash
dart run tool/registry.dart
```

It contains:

- `index.json` — the list of extensions, versions, checksums, and compatibility.
- `archives/<id>-<version>.tgz` — packaged extension archives.

## Using the registry

```bash
kiln config --registry="$(pwd)/registry"
kiln store search http
kiln store install http_retry
kiln upgrade
```

For an HTTP registry, point `--registry` or `kiln config --registry` at a URL
that serves `index.json` and the `archives/` folder. An optional mirror can be
configured with `kiln config --mirror=<url>`.

`kiln ext publish --registry=<folder>` adds one new version to the local
registry and then updates `index.json`. Publishing to an HTTP URL is not
supported; push the registry folder with Git or another release mechanism.

## Verification

Each archive is verified using the SHA-256 from the index before it is
installed. Archives with path traversal are rejected. Community extensions, or
extensions that have hooks, ask for confirmation before they are installed.

## CI check

```bash
dart run tool/registry.dart --check
```

This command compares the generated index and archives with the contents of the
`registry/` folder.
