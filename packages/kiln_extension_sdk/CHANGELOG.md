# Changelog

## 0.1.2

- Warn when `kiln remove --force` deletes a file that was edited or has no
  tracked hash.

## 0.1.1

- Add `android.receivers` to the manifest model, JSON schema, and native
  installer patches, including `exported` and intent-filter actions.
- Validate Android receiver component names, duplicate receivers, and action
  formats before install.
- Add macOS URL schemes through `macos.url_schemes`, applied to
  `macos/Runner/Info.plist`.
- Validate permissions, URL schemes, App Link hosts, and path prefixes.
- Revert URL schemes without deleting unrelated plist strings and clean up the
  empty `CFBundleURLTypes` entry.
- Add conditional native setup (`conditional` + `when`) evaluated against saved
  prompt answers; `kiln remove` and `kiln upgrade` reconstruct the same patches.
- Validate conditional setup prompt names and nested native values.

## 0.1.0

- Manifest parsing, validation, resolution, Mason rendering, transactional
  installer, native patches, verification, and migrations.
