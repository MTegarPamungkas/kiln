# Changelog

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
