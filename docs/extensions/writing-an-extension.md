# Writing an extension

## 1. Scaffold

```bash
kiln ext new hello --name "Hello extension" --provides hello
```

This command creates:

```text
extensions/hello/
├─ extension.yaml
├─ pubspec.yaml          # dev dependency for running extension tests
├─ README.md
├─ CHANGELOG.md
├─ docs/
├─ test/                 # manifest, render, analyze
└─ brick/
   ├─ brick.yaml
   └─ __brick__/
      ├─ lib/extensions/hello/
      └─ test/extensions/hello/
```

## 2. Manifest

Fill in `id`, `name`, `category`, `tier`, `provides`, `requires`, prompts,
slots, dependencies, native patches, and compatibility. See
[extension-manifest.md](../extension-manifest.md).

## 3. Module

A module registers contracts, not implementations, into the application code:

```dart
final class HelloModule extends KilnModule {
  const HelloModule();

  @override
  String get id => 'hello';

  @override
  Set<String> get provides => const {'hello'};

  @override
  void register(Registry registry) {
    registry.registerSingleton<HelloService>(HelloService());
  }
}
```

Contracts used by the application are defined in `kiln_core`. Do not create a
static facade or a global registry. Application code reads services through
`RegistryScope`/`Registry`.

## Platform support

Declare the platforms an extension can run on in `extension.yaml`:

```yaml
platforms:
  - android
  - ios
  - macos
```

Mirror the list on the module so `KilnBootstrap` skips it on other targets:

```dart
@override
Set<String> get platforms => const {'android', 'ios', 'macos'};
```

A project can still list more platforms (for example web). `kiln doctor`
reports `biometric is disabled on web` as a warning, and the app keeps working
on the supported platforms. It only fails when the extension and the project
share no platform at all.

### Device support

Platform support is only the first check. Probe the device in `support()` and
return `SupportInfo` instead of letting initialization fail:

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

When `support()` is not supported, bootstrap skips `ready()` and records the
result in `SupportRegistry`. Application code can read it without wiring:

```dart
final info = registry.read<SupportRegistry>()['my_extension'];
if (info?.isSupported ?? false) {
  // use the feature
}
```

Calls that still run while unsupported should throw
`SupportInfo.toFailure()` (or return a native unavailable status such as
`PermissionStatus.unsupported`) so the app receives explanatory information
instead of a crash.

## 4. Rules

- An extension does not import other extensions.
- Depend on capabilities, not ids.
- Provide a gateway for plugins that are hard to test.
- Map package errors to `Failure` with a stable `FailureCode`.
- Native patches must be idempotent and have stable ids.
- Do not edit files owned by another extension or `extensions.g.dart`.
- Secret prompts are not written to `kiln.yaml`.

## 5. Test and pack

```bash
kiln ext validate extensions/hello
kiln ext test extensions/hello
kiln ext pack extensions/hello
```

`pack` produces `hello-0.1.0.tgz`. `publish` waits for the registry phase.
