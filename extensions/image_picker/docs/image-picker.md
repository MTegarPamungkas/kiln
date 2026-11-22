# Image picker

`MediaPicker.pickImage()` returns `PickedImage?`; null means the user
cancelled. Every failure is thrown as a `Failure`.

```dart
final picker = registry.read<MediaPicker>();

final image = await picker.pickImage(
  source: MediaSource.camera,
  maxWidth: 1024,
  maxHeight: 1024,
  imageQuality: 80,
);

if (image != null) {
  print('${image.name} — ${image.readableSize}');
}
```

## Configuration

The `max_bytes` and `allowed_types` prompts are rendered into
`MediaPickerConfig.defaults`.

- `maxWidth`, `maxHeight`, and `imageQuality` are the default values; the
  `pickImage` arguments override them. They are downscaling targets, not reject
  limits.
- `maxBytes` is checked against the reported length before the file is read, and
  again against the streamed contents in case the length lies.
- `allowedTypes` contains MIME types. Image types not in the list are rejected.
- `maxDecodedWidth`, `maxDecodedHeight`, and `maxDecodedPixels` reject an image
  whose encoded header declares a bitmap larger than the limit, before a decoder
  allocates it. Defaults are 20000 x 20000 and 50 megapixels; pass smaller values
  when the app only needs thumbnails.

```dart
const config = MediaPickerConfig(maxDecodedPixels: 16000000);
```

The check reads only the header (PNG `IHDR`, JPEG frame header, GIF screen
descriptor, WebP `VP8X`/`VP8 `/`VP8L`, and the AVIF/HEIC `ispe` box) and skips
formats it cannot measure, because such a payload cannot be decoded into a
bitmap either. The measured size is also exposed on `PickedImage.width` and
`PickedImage.height`.

## Image types

The type is determined from the leading bytes: JPEG, PNG, GIF, WebP, HEIC, and
AVIF. The plugin's `mimeType` is only used when the bytes are unavailable,
because the plugin reports inconsistent types on some devices.

## Camera

If the `permission` extension is installed and mounts the `camera` kind,
`CameraPermissionPrecheck` requests permission before the camera opens. If the
contract is missing or cannot answer, the plugin handles the permission.

## Table of contents

- [Upload flow](upload-flow.md)
- [Platform notes](platform-notes.md)
