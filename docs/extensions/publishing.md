# Publishing extensions

## Foundation phase

Use `kiln ext pack` to produce an archive:

```bash
kiln ext pack extensions/dio --output build/dio-0.2.0.tgz
```

Then publish the archive manually or attach it to a release. `kiln ext publish`
is not active yet because the registry and `kiln_store` are still parked.

## Registry phase

Planned steps:

1. Validate the manifest and run render/analyze.
2. Build a `.tgz` archive and compute its SHA-256.
3. Write the version metadata (url, checksum, requires, compatibility, tier).
4. Update `registry/index.json`.
5. Publish to the configured registry/mirror.

Checksums are verified before installation; archives containing path traversal
are rejected.
