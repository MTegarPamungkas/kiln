# Platform notes

## Android

- **Activity destroyed while picking.** Android can kill the activity while the
  camera is open. Call `LostDataRecovery.recover()` on start to retrieve the
  leftover result.
- **Photo picker.** Android 13 and above use the system photo picker, so no
  storage permission is needed for the gallery.
- **Camera.** Opening the camera through an intent does not require the `CAMERA`
  permission if the app does not declare it. If that permission is declared,
  the app must request it itself; the precheck handles this through the
  `Permissions` contract.

## iOS and macOS

The extension adds `NSPhotoLibraryUsageDescription` and
`NSCameraUsageDescription` to `Info.plist`, plus file and camera entitlements
for macOS. The permission text can be changed in `extension.yaml` before
install.

## Web

`XFile.path` is a blob URL and cannot be used across sessions. Always upload
from `PickedImage.bytes`, not from the path. `PickedImageX.toImageProvider` uses
`MemoryImage`; without bytes it throws `Failure(media.invalid)`.

## Size limits

Limits are checked after the bytes are read. To prevent excessive memory use on
very large files, keep `max_bytes` reasonable and use `maxWidth`, `maxHeight`,
and `imageQuality` so the plugin shrinks the image before it is read.
