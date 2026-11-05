# Publishing extensions

`kiln_store` and the `registry/` folder implement the full publish path today.
`kiln ext publish` validates the manifest, builds a `.tgz`, computes its
SHA-256, writes the version metadata, and updates `registry/index.json`. The
only remaining step is publishing to a hosted HTTP registry/mirror rather than a
local `registry/` folder.

## Pack a single archive

`kiln ext pack` produces a `.tgz` for a release attachment or manual sharing:

```bash
kiln ext pack extensions/dio --output build/dio-0.1.0.tgz
```

## Publish to a registry

```bash
kiln ext publish extensions/dio --registry="$(pwd)/registry"
```

The publisher:

1. Validates the manifest and runs render/analyze.
2. Builds the `.tgz` archive and computes its SHA-256.
3. Writes version metadata (url, checksum, requires, compatibility, tier).
4. Updates `registry/index.json` and publishes to the configured folder/mirror.

`tool/registry.dart` rebuilds the entire registry from `extensions/` in one pass.

## Install-side guarantees

`kiln_store` verifies the archive checksum and applies the trust policy before
installing, and rejects archives that contain path traversal. See
[trust-tiers.md](trust-tiers.md).
