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
  `pickImage` arguments override them.
- `maxBytes` is checked after the file is read.
- `allowedTypes` contains MIME types. Image types not in the list are rejected.

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
