# Decoded image dimension limits

Date: 2026-11-20 (Asia/Jakarta). Completes the remaining scope of K28 in
[findings](../findings.md).

## Context

`DeviceMediaPicker.fromFile` already bounded the byte size before and during the
read, and `ImageValidator` rejected types outside the allowlist. What remained was
the decoded cost: a small file can declare a very large bitmap, and the decoder
allocates it before the app ever sees the result. MIME sniffing cannot catch that.

## Implementation

- `ImageDimensionsReader` reads the intrinsic size from the encoded header
  without decoding: PNG `IHDR`, JPEG start-of-frame segments (skipping APPn and
  restart markers), GIF logical screen descriptor, WebP `VP8X`/`VP8 `/`VP8L`,
  and the AVIF/HEIC `ispe` box. Every read is bounds-checked; a truncated,
  malformed or unknown header returns null.
- `MediaPickerConfig` gains `maxDecodedWidth`, `maxDecodedHeight` and
  `maxDecodedPixels` (defaults 20000, 20000, 50 megapixels). `maxWidth` and
  `maxHeight` keep their meaning: downscaling targets passed to the picker, not
  reject limits.
- `ImageValidator` rejects a measurable header above any of the three limits with
  `mediaInvalid` and the measured width, height, pixels and limits in `details`.
  A header that cannot be measured is skipped: such a payload cannot be decoded
  into a bitmap, so it cannot allocate one either.
- `DeviceMediaPicker.fromFile` fills `PickedImage.width`/`height` from the same
  parse, including when the sniffer normalizes the MIME type.

## Tests

`image_dimensions_test.dart` covers PNG, JPEG (including preceding APPn and
restart markers), GIF, WebP `VP8X`, AVIF `ispe`, pixel count, and null for
truncated/unknown headers. `image_validator_test.dart` covers a header above the
width/height limits, a pixel count above the limit within the width limits, a
small accepted image, and an unmeasurable header still accepted.
`device_media_picker_test.dart` checks the exposed size and that an oversized
bitmap is rejected before returning.

The fixtures are built in `test_support.dart` from a real 1x1 PNG and synthetic
headers for the other formats, so no binary blobs are committed.

## Verification

`image_picker` passed rendered analysis and its full rendered test suite; all
golden snapshots, metadata and documentation checks pass, and the bundle,
registry and catalog were regenerated.

## Remaining

- Real device acceptance with the image_picker plugin (gallery, camera, HEIC from
  an iPhone) is still open; the tests cover the header parsing and policy, not
  the platform plugin.
- A header can lie about its size; the decoder then rejects the file, but this
  check only bounds what the header claims. Full decode-based verification would
  need a decoder dependency and is not part of this pass.
