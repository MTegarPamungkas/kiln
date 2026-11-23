# Changelog

## 0.1.1

- Repack archive with deterministic cross-OS gzip and without root `test/`.

## 0.1.0

- Read the encoded header and reject an image whose intrinsic size exceeds
  `maxDecodedWidth`/`maxDecodedHeight`/`maxDecodedPixels` before a decoder
  allocates the bitmap; the measured size is exposed on `PickedImage`.
- Bound streamed contents even if file length under-reports; upload reuses
  configured byte/type validation and rejects names with path segments.

- Initial release.
