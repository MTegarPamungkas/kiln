# Permission

Supported kinds: camera, microphone, photos, notifications, location,
locationAlways, contacts, calendar, bluetooth, and storage.

Add native entries according to the kind in use:

- Android: `<uses-permission>` in `AndroidManifest.xml`.
- iOS: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`,
  `NSPhotoLibraryUsageDescription`, and related keys in `Info.plist`.
- macOS: camera/microphone/file entitlements.

The `kinds` prompt only controls which kinds the contract is allowed to request,
not automatic native patching.
