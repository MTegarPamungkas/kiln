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
