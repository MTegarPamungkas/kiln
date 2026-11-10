# Contracts and capabilities

`kiln_core` is the only package that application code and all extensions know
about. Contracts are available for:

HTTP (`HttpClient`, `HttpPipeline`, `HttpCache`), storage (`Storage`,
`SecureStorage`, `LocalDatabase`, `RemoteDatabase`, `FileStorage`), auth
(`AuthRepository`, `AccountManagement`, `SocialAuth`, `TokenProvider`),
platform (`NetworkMonitor`, `Permissions`, `Notifications`, `DeepLinks`,
`MediaPicker`), observability (`Analytics`, `CrashReporter`, `AppLogger`), and
configuration (`Env`, `AppFlavor`).

## Capabilities

Extensions declare `provides` and `requires` in the manifest. The resolver
picks a provider for every `requires`; an extension never writes another
extension's id.

- Two providers for the same capability = conflict.
- Missing capability = conflict with an install suggestion.
- `exclusive: true` rejects other extensions in the same category.
- `when` on a slot contribution is active only while that capability exists.

Application code reads contracts from the Registry:

```dart
final client = RegistryScope.read<HttpClient>(context);
```

Concrete implementations such as `DioClient` are not imported by the
application.

Capabilities decide whether a provider is installed. They do not promise that
the current device can use it. Runtime readiness is reported separately by
`KilnModule.support()` and exposed through `SupportRegistry`; see
[../extensions/support-and-devices.md](../extensions/support-and-devices.md).

## Behavior, not just method names

Every provider must return the same observable outcomes: missing records,
pagination, combined filters, logout failures, and unsupported backends are
specified in [contract-behavior.md](contract-behavior.md). The executable
version lives in the `kiln_testing` contract suites.
