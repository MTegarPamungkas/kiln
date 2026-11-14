# Push transport

The `push_transport` capability is the receiving half of the push flow:
it bridges Firebase Cloud Messaging into kiln and keeps the backend's device
address book in sync.

## The four-step push flow

1. **Device obtains a token** — `firebase_messaging` (this extension).
2. **Token registered on the backend** — done here through the `push_targets`
   capability of the `appwrite` extension, including automatic rotation.
3. **Backend sends a message** — Appwrite Messaging provider (FCM), configured
   in the console with the same Firebase project's service account.
4. **Device receives the message** — foreground envelopes surface on
   `PushTransport.foreground`; background messages land in the system tray.

## Usage

```dart
final transport = registry.read<PushTransport>();

final token = await transport.token(); // current FCM token
transport.foreground.listen((envelope) {
  // envelope.title / envelope.body / envelope.data
});
```

## Setup (manual steps `kiln doctor` reminds)

1. `google-services.json` at `android/app/` from the Firebase project, and the
   Google Services Gradle plugin applied — or run `flutterfire configure`.
2. A Firebase Cloud Messaging provider in the Appwrite console with the same
   project's service account, so the backend can deliver.
