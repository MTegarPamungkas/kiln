# Runtime support and devices

Kiln separates three questions:

1. **Manifest compatibility** — can the extension run on a platform at all?
   `extension.yaml` and `KilnModule.platforms` answer this at build time.
2. **Runtime support** — does this device, service, or configuration allow the
   extension right now? `KilnModule.support()` answers this during bootstrap.
3. **Operation outcome** — did a call succeed? Contracts still throw `Failure`
   for network, permission, and validation errors at call time.

Support is informational. The application does not need to wire platform or
hardware checks itself; bootstrap probes and records the result.

## Contract

```dart
final class SupportInfo {
  const SupportInfo.supported({message, details});
  const SupportInfo.unsupported(SupportState state, {required message, details});

  final SupportState state;
  final String message;
  final Map<String, Object?> details;

  bool get isSupported;
  bool get isPlatformUnsupported;
  bool get isDeviceUnsupported;
  Failure toFailure({String? message});
}
```

States:

| State | Meaning |
| --- | --- |
| `supported` | The extension can be used now |
| `unsupportedPlatform` | No implementation for this platform |
| `unsupportedDevice` | The platform exists but this device lacks the capability |
| `permissionDenied` | Capability exists but is not enrolled/allowed |
| `notConfigured` | Required keys, credentials, endpoints, or flavor are missing |
| `unavailable` | A service, plugin, path, or initialization is unavailable |

`SupportInfo.toFailure()` maps the state to a stable failure code:

- `support.unsupported_platform`
- `support.unsupported_device`
- `configuration.missing`
- `permission.denied`
- `unavailable`

## Lifecycle

`KilnBootstrap` creates a `SupportRegistry` and registers it before any module
runs:

1. Modules filtered out by `platforms` are recorded as `unsupportedPlatform`.
2. Each active module registers its contracts.
3. Bootstrap calls `KilnModule.support(registry)` with a default timeout.
4. The result is recorded in `SupportRegistry`.
5. `ready()` runs only when the result is supported.
6. Probe errors and timeouts are recorded as `unavailable`; the app keeps
   starting.

A module whose probe fails should still register its contracts so callers get a
typed failure instead of a missing-service error. Unsupported calls return
`SupportInfo.toFailure()` or a native unavailable status such as
`PermissionStatus.unsupported`.

## Reading the report

```dart
final support = registry.read<SupportRegistry>();

final biometric = support['biometric'];
if (biometric?.isSupported ?? false) {
  // show the biometric action
} else {
  // show biometric?.message and fall back to another method
}

final all = support.all; // Map<String, SupportInfo>
```

The registry is available to the application, `SupportRegistry.changes` emits
updates, and `kiln doctor` still reports manifest/platform compatibility.
Runtime device support exists only inside the running app.

## Extension coverage

Every bundled extension reports support. The probe is intentionally cheap and
must not prompt the user.

| Extension | Probe | Not-supported states |
| --- | --- | --- |
| `analytics` | API key, host, flavor, PostHog setup | `notConfigured`, `unsupportedPlatform`, `unavailable` |
| `appwrite` | endpoint, project, database, bucket | `notConfigured` |
| `biometric` | platform, hardware, enrollment | `unsupportedPlatform`, `unsupportedDevice`, `permissionDenied` |
| `bloc` | app wrapper and observer wiring | always supported |
| `calendar` | native calendar UI on Android/iOS | `unsupportedPlatform` on other targets |
| `connectivity` | platform connectivity check | `unsupportedPlatform`, `unavailable` |
| `deep_link` | initial link probe | `unsupportedPlatform`, `unavailable` |
| `dio` | base URL and timeouts | `notConfigured` |
| `env` | required build-time keys | `notConfigured` |
| `firebase` | options and Firebase initialization | `notConfigured`, `unavailable` |
| `flavors` | registered `AppFlavor` | `notConfigured` |
| `geolocation` | service enabled and permission without prompting | `unavailable`, `permissionDenied`, `unsupportedPlatform` |
| `go_router` | initial location and route count | `notConfigured` |
| `http_cache` | TTL, entry count, status codes, backend | `notConfigured` |
| `http_retry` | attempts and delays | `notConfigured` |
| `image_picker` | camera/gallery per source | `unsupportedDevice`, `unsupportedPlatform` |
| `l10n` | locales, fallback, preference storage | `notConfigured` |
| `local_db` | writable application storage | `unsupportedPlatform`, `unavailable` |
| `logger` | file sink probe and sink settings | degraded `supported` with `file: false`; `notConfigured` |
| `notifications` | plugin initialization | `unsupportedPlatform`, `unavailable` |
| `permission` | per-kind status probe | per-kind `unsupportedDevice`/`unsupportedPlatform` |
| `rest_auth` | endpoints and secure token store | `notConfigured`, `unsupportedPlatform`, `unavailable` |
| `riverpod` | app wrapper wiring | always supported |
| `secure_storage` | Keychain/Keystore/WebCrypto read | `unsupportedPlatform`, `unavailable` |
| `share` | platform share sheet | `unsupportedPlatform` on Linux |
| `social_login` | provider platform and credentials | `unsupportedPlatform`, `notConfigured` |
| `storage` | SharedPreferences read | `unsupportedPlatform`, `unavailable` |
| `supabase` | config and client load | `notConfigured`, `unavailable` |
| `theme` | theme settings and preference storage | `notConfigured` |

Some extensions expose finer-grained probes:

- `PermissionSupport.forKind(kind)` and `Permissions.status()` return
  `PermissionStatus.unsupported` for a missing kind.
- `MediaPickerSupport.forSource(MediaSource.camera)` separates camera and
  gallery support.
- `SocialLoginSupport.forProvider(provider)` separates Google and Apple.
- `LoggerSupport` reports `file: false` while console, memory, and breadcrumb
  sinks continue working.

## Writing an extension

```dart
@override
Future<SupportInfo> support(Registry registry) async {
  final probe = await registry.read<MySensor>().probe();
  return probe.isAvailable
      ? const SupportInfo.supported()
      : const SupportInfo.unsupported(
          SupportState.unsupportedDevice,
          message: 'This device has no sensor.',
        );
}
```

See [writing-an-extension.md](writing-an-extension.md) for the full extension
contract.
