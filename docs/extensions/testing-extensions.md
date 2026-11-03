# Testing extensions

There are three layers of tests.

## 1. Tests inside the brick

Files under `brick/__brick__/test/extensions/<id>/` are rendered into the user
application and run there. Examples:

- module tests that register services with the Registry,
- failure mapper tests,
- widget/helper tests,
- `*_contract_test.dart` files that run a suite from `kiln_testing`.

## 2. Extension-level tests

Files in the extension's `test/` folder:

- `manifest_test.dart` — the manifest is valid against the schema and validator.
- `render_test.dart` — render the brick to a temp folder and compare against the
  golden.
- `analyze_test.dart` — the rendered output passes `flutter analyze`.

`ExtensionTestHarness` provides `loadManifest`, `validateManifest`, `bundle`,
and `render`.

## 3. Contract suite

`kiln_testing` provides suites for HttpClient, Storage, SecureStorage,
AuthRepository, AccountManagement, SocialAuth, LocalDatabase, RemoteDatabase,
FileStorage, NetworkMonitor, Permissions, Notifications, DeepLinks,
MediaPicker, Analytics, CrashReporter, and AppLogger.

Implementations of the same contract must pass the same suite. That is the proof
that backends and transports can be swapped.

## Running

```bash
kiln ext test extensions/dio
```

In this repo every extension has a dev-only pubspec and is a workspace member,
so `dart test` and `flutter analyze` use consistent dependencies.
