# appwrite_push

Push transport for the Appwrite backend. Bridges Firebase Cloud Messaging
into two existing kiln capabilities:

- `push_targets` (from the `appwrite` extension) — the FCM token is registered
  on the signed-in user's Appwrite account, refreshed automatically on token
  rotation.
- `notifications` (optional) — foreground messages are surfaced as local
  notifications.

Provides `PushTransport` from `kiln_core`: the current transport token plus a
stream of envelopes received while the app is in the foreground.

## Install

```bash
kiln add appwrite_push
```

Requires the `appwrite` extension (push targets) and a Firebase project wired
into the Android build (google-services.json + Google Services Gradle plugin,
or `flutterfire configure`). To deliver pushes, add a Firebase Cloud Messaging
provider in the Appwrite console (Messaging) using the same Firebase project's
service account. See [docs/push-transport.md](docs/push-transport.md).

## Usage example

```dart
final transport = registry.read<PushTransport>();
final token = await transport.token();
debugPrint('FCM token: $token');

transport.foreground.listen((envelope) {
  debugPrint('${envelope.title}: ${envelope.body}');
});
```
