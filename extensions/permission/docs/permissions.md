# Permission

Kind yang didukung: camera, microphone, photos, notifications, location,
locationAlways, contacts, calendar, bluetooth, dan storage.

Tambahkan entri native sesuai kind yang dipakai:

- Android: `<uses-permission>` di `AndroidManifest.xml`.
- iOS: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`,
  `NSPhotoLibraryUsageDescription`, dan kunci terkait di `Info.plist`.
- macOS: entitlement kamera/mikrofon/file.

Prompt `kinds` hanya mengatur kind yang boleh diminta oleh kontrak, bukan patch
native otomatis.
