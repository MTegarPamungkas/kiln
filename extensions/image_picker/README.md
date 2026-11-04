# image_picker

An implementation of `MediaPicker` from `kiln_core` on top of the
`image_picker` plugin.

- `DeviceMediaPicker` uses the dimension, quality, and maximum size limits from
  the prompt.
- `MimeSniffer` determines the image type from the leading bytes, not from the
  plugin's `mimeType`.
- `ImageValidator` rejects images that are too large or of a disallowed type
  with `Failure(media.invalid)`.
- `CameraPermissionPrecheck` checks the `Permissions` contract first so that
  permission denials are clear.
- `LostDataRecovery` recovers the pick result when the Android activity is
  destroyed.
- `PickedImageUploadAdapter` turns `PickedImage` into `FileUpload` for
  `FileStorage`; the adapter is only registered when that contract exists.
- Applications choose camera or gallery in their own UI and call `MediaPicker`.

Platform limits and native notes are in
[docs/platform-notes.md](docs/platform-notes.md). The upload flow is in
[docs/upload-flow.md](docs/upload-flow.md).

## Gate

```dart
final image = await gate.pickImage(source: MediaSource.gallery); // Result<PickedImage?>
final photo = await gate.pickImage(source: MediaSource.camera, maxWidth: 1080);
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
