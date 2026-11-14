# Push transport

The `push_transport` capability implemented over Appwrite Push. Unlike FCM or
APNs delivery, this transport has no device token and no Firebase project: the
Appwrite SDK keeps an MQTT connection and subscribes to the signed-in user's
own topic.

## The flow

1. **The user signs in** through the `appwrite` extension, which owns the
   client and restores the session at startup.
2. **The module subscribes** to `users/<userId>` once a session exists and
   drops the subscription on sign-out. Re-subscribing happens automatically on
   the next sign-in, and on the new topic when a different user signs in on the
   same client.
3. **The backend sends a message** with `messaging.createPush` to the user id;
   no push target registration is involved.
4. **The device receives it** through the Appwrite SDK: foreground messages
   reach `PushTransport.foreground`, background messages are shown by the SDK
   (Android keeps a background service; iOS uses APNs), and taps arrive on
   `AppwritePushNativeTransport.opened`. The tap that launched the app is
   replayed to the first `opened` listener.

## Payload

`PushEnvelope` is built from the message payload:

```json
{
  "notification": { "title": "Kiln", "body": "Hello" },
  "data": { "route": "/inbox" }
}
```

`title` and `body` come from `notification`; `data` is passed through when it
is a JSON object.

## Lifecycle

- Subscribe happens after `AuthRepository.currentSession` exists; the module
  follows `authStateChanges`, so sign-out unsubscribes and the next sign-in
  subscribes again.
- A different user on the same client drops the previous subscription before
  opening the new one.
- A subscribe failure is reported on `errors`/`lastError` and retried on the
  next session change instead of breaking bootstrap.
- `dispose()` cancels the auth listener, drops the subscription, and closes the
  streams.

## Setup

1. In the Appwrite console, open Messaging and create an **Appwrite** push
   provider. No credentials are required.
2. Android: no Firebase files. The transport requests the notification
   permission through the SDK; exact alarms and battery optimisation only
   affect background latency, so ask for them from a user action when needed.
3. iOS: enable Push Notifications and the remote-notification background mode,
   and configure APNs credentials on the Appwrite provider.

## Configuration

The install prompts render [AppwritePushNativeConfig]:

- `push_endpoint` (default empty) — MQTT broker endpoint such as
  `mqtts://push.example.com:8883`. Blank lets the SDK derive `push.<api host>`
  (Appwrite Cloud). Self-hosted servers usually need it because the broker
  lives on port 8883, which a Cloudflare-proxied API hostname does not expose.
- `background` (default `true`) — the SDK keeps delivering while the app is
  backgrounded and posts notifications. Set it to `false` for foreground-only
  delivery, for example in tests.
- `notification_title` (default `Notifications`) — title on background
  notifications.

## Trade-offs

- Android delivery uses scheduled wake-ups while the app is closed, so it is
  less immediate than FCM. `setForeground(true)` (exposed by the Appwrite SDK)
  can keep a foreground service for low latency.
- Do not install this extension together with `appwrite_push` (FCM): both
  provide `push_transport`, and receiving on both providers would duplicate
  notifications.
