# Changelog

## 0.1.1

- `kiln upgrade` resolves prompts before touching the project and rolls back
  managed files when verification fails.
- `kiln upgrade` now applies bundled-catalog upgrades when no registry is
  configured, instead of only listing the candidates.
- Registry caches are scoped to the registry identity and verify the selected
  checksum before extraction.

## 0.1.0

- Initial release.
