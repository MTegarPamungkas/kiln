# Changelog

## 0.1.3

- Widen `flutter_local_notifications` constraint to `>=22.3.3 <24.0.0` so it
  allows 23.x while staying compatible with `appwrite` 28.x.
- Update `firebase_core` to `^5.2.0` and `firebase_messaging` to `^17.1.0`.

## 0.1.2

- Repack archive with deterministic cross-OS gzip and without root `test/`.

## 0.1.1

- The transport stops between awaits if the module was disposed during
  Firebase initialization, and the module does not register its global background
  handler after disposal.
- Background and terminated pushes now render into the system tray through a
  registered `onBackgroundMessage` handler (Appwrite delivers data payloads,
  which the platform does not display automatically).
- The runtime module now restricts itself to Android, matching the manifest.

## 0.1.0

- Initial release. Bridges Firebase Cloud Messaging into the `push_transport`
  capability: mints the device token, keeps the Appwrite push target in sync
  through the `push_targets` capability, and surfaces foreground messages.
