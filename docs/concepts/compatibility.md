# Compatibility

An extension manifest can constrain:

```yaml
compatibility:
  kiln: ">=0.1.0 <0.2.0"
  dart: ">=3.9.0"
  flutter: ">=3.35.0"
```

`compatibility.kiln` refers to the running CLI. Install, upgrade, and doctor use
that version and the running Dart and Flutter toolchains. Explicit registry
versions obey the same constraints as automatic selection. Installation
rejects extensions that support none of the project targets. The generated
app and its dependencies can impose a higher minimum than an extension.

Version rules:

- Extensions use semver.
- The lockfile records the exact version installed.
- Registry upgrades can select earlier compatible versions and run migrations from the selected archive.
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
