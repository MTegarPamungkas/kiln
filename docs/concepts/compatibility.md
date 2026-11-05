# Compatibility

An extension manifest can constrain:

```yaml
compatibility:
  kiln: ">=0.1.0 <0.2.0"
  dart: ">=3.9.0"
  flutter: ">=3.35.0"
```

`kiln doctor` checks these ranges against the running CLI and Dart versions. The
resolver can also reject unsupported platforms through `platforms`.

Version rules:

- Extensions use semver.
- The lockfile records the exact version installed.
- Multi-version upgrade and the migration runner wait on the registry catalog.
- An extension's dependency constraints are written in `dependencies` and added
  to the user project's `pubspec.yaml`.

## Platform versus device

`platforms` is a build-time filter. It does not tell you whether the current
device has a camera, biometric hardware, a writable documents directory, or a
working desktop keyring.

Runtime support is reported separately:

- `KilnModule.support()` returns a `SupportInfo` after registration.
- `KilnBootstrap` records it in `SupportRegistry` and skips `ready()` when the
  extension is not supported.
- Unsupported calls return `support.unsupported_platform` /
  `support.unsupported_device` failures, or a native unavailable status such as
  `PermissionStatus.unsupported`.

Support results are informational; they are not permanent compatibility
declarations. A supported extension can still fail later because of network,
permissions, or invalid data. See
[../extensions/support-and-devices.md](../extensions/support-and-devices.md).
