# Push targets

The extension's `push_targets` capability wraps the [PushTargets](../../../packages/kiln_core/lib/src/contracts/push_targets.dart)
contract: the application registers the device's push token on the Appwrite
project for the signed-in user, so the backend knows where to deliver pushes.

## Where this fits

Push delivery is a four-step flow, and this capability is only step two:

1. **Device obtains a token** from Firebase Cloud Messaging (FCM) or APNs.
   That transport setup (a Firebase project and `google-services.json`) lives
   outside this capability.
2. **App registers the token** with `PushTargets.register` — this capability.
   Appwrite keeps one target per provider per session; a rotated token updates
   the existing target.
3. **Backend sends a message** through an Appwrite Messaging provider (for
   Android, the FCM provider) — configured in the console, or automated from a
   function.
4. **Device receives the message** through the platform transport and surfaces
   it, typically with the `notifications` capability.

## Usage

```dart
final pushTargets = registry.read<PushTargets>();

final target = await pushTargets.register(token: fcmToken);
// target.id — store it if you want to rotate or remove later

final rotated = await pushTargets.update(
  targetId: target.id,
  token: newFcmToken,
);

await pushTargets.unregister(targetId: target.id);
```

`register` requires a signed-in session (targets belong to a user). Failures:
an unknown or missing target is `push_targets.not_found`; being signed out is
`auth.unauthorized`; transport and rate-limit errors are retryable.
