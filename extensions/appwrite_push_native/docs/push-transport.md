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

- When `go_router` is installed, it automatically follows the transport's
  `PushNotificationOpens.notificationTaps` stream. Send a local location in
  `data.route`, such as `/orders/42?tab=items`. Appwrite-specific `opened`
  remains available for custom consumers; a retained launch tap is replayed
  to the first listener, so let the router own navigation rather than consuming
  the initial tap separately. Foreground receipt alone never navigates.
- Enable the router's auth redirect to preserve a protected tap destination
  through session restoration and login. No local Notifications provider or
  manual Appwrite-to-router forwarding is needed for native push taps.
- Subscribe happens after `AuthRepository.currentSession` exists; the module
  follows `authStateChanges`, so sign-out unsubscribes and the next sign-in
  subscribes again.
- A different user on the same client drops the previous subscription before
  opening the new one.
- A subscribe failure is reported on `errors`/`lastError` and retried with
  exponential backoff (`retryBaseDelay`, doubling up to `retryMaxDelay`).
  `retryNow()` skips the wait, for example when the app notices the network
  returned.
- `start()` waits for the first subscription at most `subscribeTimeout`
  (default 10 s). A broker that accepts the socket but never acknowledges the
  subscription therefore cannot stall bootstrap: the timeout is reported and the
  retry is scheduled. `pendingRetryDelay`/`retryAttempt` expose that state.
- A tap on the same notification is delivered once. The transport deduplicates
  by Messaging id (or topic plus payload when the sender did not use Messaging)
  inside `tapDedupeWindow` (default 2 s), which covers a double tap and the SDK
  reporting a launch tap twice. `duplicateTapsIgnored` counts the suppressions.
- `dispose()` cancels the auth listener, the retry timer, the subscription, and
  closes the streams.

## Background reliability

Delivery while the app is closed is best effort on both mobile platforms: the
OS defers wake-ups, and the user can restrict background usage. The transport
implements the core `PushDeliveryControls` capability so an application can
explain that and ask, from a user action:

```dart
final push = registry.read<AppwritePushNativeTransport>();
final status = await push.status(); // null when the platform cannot report it
if (status?.bestEffort ?? false) showBatteryNote();
await push.requestIgnoreBatteryOptimizations(); // Android: ask for Unrestricted
await push.requestExactAlarms();                // Android 12+: punctual wake-ups
await push.setForeground(true);                 // immediate delivery while visible
```

`setForeground(true)` must be called while the app is in the foreground, needs
the `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_REMOTE_MESSAGING` permissions
declared in the app, and shows an ongoing notification. The
`background_reliability` install prompt declares the Android
`SCHEDULE_EXACT_ALARM` and `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permissions
used by the two requests; declaring them does not grant them.

## Notification actions are not supported

The Appwrite Flutter SDK builds its own single-tap notification
(`NotificationCompat.Builder` with `setAutoCancel(true)` and no `addAction`), so
action buttons cannot be added without replacing the SDK's notification
pipeline, which would also replace its delivery and tap handling. This extension
does not do that. Use one notification per action with a distinct
`data.route` instead: each notification is a separate tap target, and the router
already follows the route.

## Setup

1. In the Appwrite console, open Messaging and create an **Appwrite** push
   provider. No credentials are required.
2. Android: no Firebase files. The transport requests the notification
   permission through the SDK; exact alarms and battery optimisation only
   affect background latency, so ask for them from a user action when needed.
3. iOS: enable Push Notifications and the remote-notification background mode,
   and configure APNs credentials on the Appwrite provider. With the `background`
   prompt left on, the installer already adds `UIBackgroundModes:
   remote-notification` to `ios/Runner/Info.plist`. The SDK runs the background
   MQTT connection in a background isolate on iOS, so delivery while suspended
   depends on that mode and on APNs being configured server-side; iOS delivery
   has not been verified on a device in this repository yet.

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
- `background_reliability` (default `false`) — declares the Android
  `SCHEDULE_EXACT_ALARM` and `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permissions
  so [PushDeliveryControls] requests can be offered. Pass `true` only when the
  app asks the user from a settings screen; the permissions stay denied until
  the user agrees.

## Trade-offs

- The native extension supports Android/iOS. A DNS-only TLS MQTT endpoint on
  port 8883 does not establish browser delivery; a browser transport needs a
  reachable secure WebSocket endpoint. Android background callback receipt is
  tested separately from notification display, taps and terminated-app delivery.
- Android delivery uses scheduled wake-ups while the app is closed, so it is
  less immediate than FCM. `setForeground(true)` (exposed by the Appwrite SDK)
  can keep a foreground service for low latency.
- Do not install this extension together with `appwrite_push` (FCM): both
  provide `push_transport`, and receiving on both providers would duplicate
  notifications.
