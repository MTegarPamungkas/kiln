# Manual step: flutterfire configure

This extension marks `firebase_flutterfire_configure` as a manual step tracked by
`kiln doctor`. The Mason hook only gives a warning; installation still completes
even if this step has not been done.

## What must be present

- The `flutterfire` CLI is available on `PATH`.
- `lib/firebase_options.dart` contains `DefaultFirebaseOptions.currentPlatform`.
- The generated native files: `google-services.json` (Android),
  `GoogleService-Info.plist` (iOS/macOS), and the web configuration in
  `firebase_options.dart`.

## Command

```bash
dart pub global activate flutterfire_cli
flutterfire configure \
  --project=<project-id> \
  --platforms=android,ios,macos,web
```

Re-run that command every time a new Firebase application is registered. Commit
`lib/firebase_options.dart`; this file contains no secrets and is needed by the
CI build.

## When using explicit options

Change the `options_source` prompt to `explicit` when installing the extension,
then build `FirebaseOptions` from your own build configuration and pass it to
`FirebaseModule(options: ...)`. The hook no longer checks
`lib/firebase_options.dart`.
