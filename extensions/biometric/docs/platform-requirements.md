# Platform requirements

## Android

- The extension adds the `USE_BIOMETRIC` permission.
- The main activity is replaced with `FlutterFragmentActivity`; the `local_auth`
  plugin needs it to show the prompt.
- The built-in prompt uses `BiometricPrompt` on Android 9 and above, and the
  AppCompat compatibility layer on older versions.

## iOS and macOS

- The extension adds `NSFaceIDUsageDescription`.
- The user must already have Face ID or Touch ID enrolled on the device.
- Simulators can report hardware without enrollment; test the full flow on a
  device.

## Web and desktop

This extension does not support web. The `unsupportedPlatform` status is
returned, and `authenticate()` throws `Failure(unavailable)`. Windows and Linux
are also not part of the platforms supported by this extension even though
`local_auth` has an experimental implementation.
