# Push notifications

Kiln ships two push transports. They both implement `PushTransport` from
`kiln_core`, so application code reads the same capability; pick the backend
that matches how the server sends messages.

| | `appwrite_push` | `appwrite_push_native` |
| --- | --- | --- |
| Delivery | Firebase Cloud Messaging | Appwrite Push (MQTT) |
| Device token | FCM token, registered as a push target | None; the SDK subscribes as the user |
| Firebase project | Required | Not required |
| Extra setup | `google-services.json` + FCM provider | **Appwrite** provider in Messaging |
| Background | OS/FCM | Android SDK service; iOS via APNs |
| Best for | Servers already using FCM, lowest latency | Firebase-free apps, or servers using Appwrite Messaging |

Both extensions provide the same capability and are exclusive: install one.

## Appwrite Push

```bash
kiln add appwrite_push_native
```

Create an **Appwrite** push provider in the Appwrite console (Messaging). It
needs no credentials. The transport uses the `appwrite` extension's client and
signed-in session:

```dart
final transport = registry.read<PushTransport>();
transport.foreground.listen((envelope) {
  openRoute(envelope.data['route']);
});

final appwritePush = registry.read<AppwritePushNativeTransport>();
appwritePush.opened.listen((opened) => openRoute(opened.data['route']));
appwritePush.errors.listen(logPushError);
```

On self-hosted servers the MQTT broker is usually a separate `mqtts://` host on
port 8883. A Cloudflare-proxied API hostname does not forward that port, so use
a DNS-only hostname and set the install prompt:

```yaml
push_endpoint: mqtts://push.example.com:8883
```

The broker needs a valid TLS certificate; mobile clients reject the default
self-signed Traefik certificate. Keep the port's attack surface small: TLS and
Appwrite session/JWT authentication are mandatory, and a per-source connection
limit is cheap insurance.

## FCM

```bash
kiln add appwrite_push
```

Requires a Firebase project wired into the Android build and an FCM provider in
Appwrite Messaging that uses the same service account. The extension registers
the FCM token as a push target and rotates it automatically.

## Background and taps

- Foreground messages always arrive on `PushTransport.foreground`; the
  application decides how to render them.
- `appwrite_push_native` lets the SDK post background notifications and
  exposes taps on `opened`; the launch tap is replayed to the first listener.
- On Android, background wake-ups are periodic unless the app opts into a
  foreground service or battery-optimisation exemption.
- On iOS, background notifications still travel through APNs and need the
  remote-notification background mode.

See [appwrite_push_native](../../extensions/appwrite_push_native/README.md) and
[appwrite_push](../../extensions/appwrite_push/README.md) for setup details, and
the [contracts reference](../reference/contracts.md) for `PushTransport`.
