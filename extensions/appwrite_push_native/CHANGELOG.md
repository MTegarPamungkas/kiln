# Changelog

## 0.2.0

- Bound `start()` with `subscribeTimeout` so a broker that never acknowledges
  cannot stall bootstrap, and retry a failed subscription with exponential
  backoff (`retryBaseDelay` growing to `retryMaxDelay`) plus `retryNow()`.
- Deduplicate repeated taps on the same notification inside `tapDedupeWindow`,
  covering double taps and the SDK reporting a launch tap twice.
- Implement the core `PushDeliveryControls` capability: `status()`,
  `setForeground()`, `requestExactAlarms()` and
  `requestIgnoreBatteryOptimizations()`, forwarded to the SDK when its driver
  supports them.
- Declare the iOS `remote-notification` background mode and add the opt-in
  `background_reliability` prompt for the Android exact-alarm and
  battery-optimisation permissions.
- Carry the Messaging `messageId` on `AppwritePushOpened` for tap identity.
- Document that notification action buttons are not supported by the SDK's
  notification pipeline, and that delivery while the app is closed is best
  effort.

## 0.1.0

- Expose generic notification taps through PushNotificationOpens, preserving
  launch-tap replay, so go_router can navigate without importing this extension.
- Invalidate pending subscriptions and message callbacks immediately when the
  session identity changes, preventing late delivery after logout.
- Initial release. Implements the `push_transport` capability over Appwrite
  Push: subscribes to the signed-in user's topic through the Appwrite SDK,
  streams foreground envelopes, and exposes background notification taps.
- Re-subscribes when a different user signs in on the same client, replays the
  launch tap to the first `opened` listener, and reports subscribe failures on
  `errors`/`lastError`.
