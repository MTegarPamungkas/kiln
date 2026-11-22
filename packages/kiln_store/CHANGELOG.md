# Changelog

## 0.1.1

- Enforce download size limits while consuming HTTP/file streams and bound
  gzip expansion before parsing tar entries. Abort timed-out HTTP requests.

- Cache entries are namespaced per registry identity.
- Every cached archive is verified against the caller-selected SHA-256 before
  extraction; offline use requires matching cached metadata.

## 0.1.0

- Initial release.
