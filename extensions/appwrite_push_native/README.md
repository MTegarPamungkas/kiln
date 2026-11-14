# appwrite_push_native

Push transport for Appwrite Push: notifications arrive over Appwrite's MQTT
connection, so the app needs no Firebase project and registers no device token.

Provides `PushTransport` from `kiln_core`:

- `foreground` emits envelopes while the app is running.
- `token()` returns null; Appwrite Push addresses signed-in users, not devices.
- Background messages are posted by the Appwrite SDK; taps surface on
  `opened`, including the tap that launched the app.
- `errors` and `lastError` report subscription failures that happen outside an
  awaited call.

## Install

```bash
kiln add appwrite_push_native
```

Requires the `appwrite` extension: the transport subscribes with the same
signed-in session and client, and re-subscribes when a different user signs in.
In the Appwrite console, create an **Appwrite** push provider under Messaging
(it needs no credentials). See [docs/push-transport.md](docs/push-transport.md).

## Usage example

```dart
final transport = registry.read<PushTransport>();

transport.foreground.listen((envelope) {
  debugPrint('${envelope.title}: ${envelope.body}');
});

final push = registry.read<AppwritePushNativeTransport>();
// Replays the notification that launched the app, then live taps.
push.opened.listen((opened) {
  debugPrint('tapped topic ${opened.topic}: ${opened.data}');
});

push.errors.listen((error) => debugPrint('push error: $error'));
```

## Limits

- Android keeps delivering while the app is closed through the SDK's background
  service; exact alarms and battery optimisation change its latency.
- iOS shows background notifications through APNs and needs the
  remote-notification background mode.
- Offline devices replay missed messages for up to 7 days (newest five).
