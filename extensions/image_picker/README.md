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
- `ImageSourceSheet` and `AvatarPicker` are ready to use in the UI.

Platform limits and native notes are in
[docs/platform-notes.md](docs/platform-notes.md). The upload flow is in
[docs/upload-flow.md](docs/upload-flow.md).
