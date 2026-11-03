# Changelog

## 0.2.0

- Removed `ImageSourceSheet` and `AvatarPicker`. Applications call `MediaPicker` and build their own picker UI.

## 0.1.1

- Add `MediaPickerSupport` with per-source platform/device checks.
- Camera requests on unsupported desktops return
  `support.unsupported_device` instead of calling the plugin.

## 0.1.0

- Initial media picker, validation, MIME sniffing, permission precheck, lost
  data recovery, upload adapter, and widgets.
