# Changelog

## Unreleased

- Exclude an extension's own root `test/` directory from release archives.
  Installing an extension reads only `extension.yaml`, `brick/`, and `docs/`,
  so the suite was dead weight that also made every test-only edit change the
  archive digest and trip the immutable-version guard. The rendered suite under
  `brick/__brick__/test/` is still packed, because it ships to applications.

## 0.1.1

- Keep published archive checksums and URLs stable per version. Repeated
  publishing can accept identical content.
- Apply Dart and Flutter constraints when selecting registry candidates.

- Limit archive entry count and per-entry size before extraction. Loopback
  tests cover registry request timeouts, streaming size limits, and successful
  index parsing.

- Enforce download size limits while consuming HTTP/file streams and bound
  gzip expansion before parsing tar entries. Abort timed-out HTTP requests.

- Cache entries are namespaced per registry identity.
- Every cached archive is verified against the caller-selected SHA-256 before
  extraction; offline use requires matching cached metadata.

## 0.1.0

- Initial release.
