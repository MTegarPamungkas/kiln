# Remaining acceptance and decisions

Use the [audit backlog](current-status.md) for priority and open engineering
findings. The sections here define the remaining work from the internal
review. Evidence for completed runs is linked where it establishes a baseline.

## K06 and K07 · Biometric and Keychain

- **K06:** Exercise temporary and permanent biometric lockout. Bulk reads
  should expose a typed failure and return no values. Cancellation, lack of
  enrollment, and successful single-prompt bulk reads have Android evidence.
  [Android biometric report](evidence/biometric-bulk-read-device-2026-11-22.md)
- **K07:** Reinstall on iOS with a custom Keychain service/access group. Verify
  that first-run wipe removes keys in the configured namespace and keeps an
  unrelated entry in the same group. [Secure storage changelog](../../extensions/secure_storage/CHANGELOG.md)

## K08 and K28 · Notification launch and media on iOS

- **K08:** Tap a delivered notification after termination. Verify that the
  destination survives bootstrap and the signed-out redirect.
  [Android routing evidence](evidence/appwrite-push-routing-2026-11-20.md)
- **K28:** Exercise the iOS gallery and camera, HEIC metadata, and cancellation.
  Confirm the byte and dimension limits through the real picker.
  [Android picker evidence](evidence/image-picker-device-2026-11-22.md)

## K09 · Telemetry consent on iOS

Capture native iOS PostHog and Sentry traffic across deny, grant, and revoke.
Include queued events and automatic Sentry events. The Android and browser
reports provide the expected traffic baseline.
[Android](evidence/k09-native-device-2026-11-22.md) · [Web](evidence/analytics-crash-live-sdk-2026-11-22.md)

## K23 · Appwrite push routing and device delivery

- Reproduce multi-provider FCM routing with a target that leaves
  `providerId` unset. Choose an explicit provider option, a documented
  single-provider configuration, or an upstream fix. A successful Messaging
  response alone does not establish delivery.
- Verify foreground and terminated delivery for `dev.tegar.appwrite_demo` on
  physical Android, plus iOS/APNs, MQTT broker acceptance, Doze/reboot, and
  token rotation for a provider-bound target.
- Verify a notification tap reaches app routing through foreground and
  terminated paths. The emulator pass showed system-tray rendering on a
  fallback channel and a tap that opened the app without surfacing its payload.

[FCM emulator and routing evidence](evidence/fcm-push-emulator-2026-11-23.md)
· [Appwrite adapter evidence](evidence/k23-live-adapters-2026-11-22.md)
· [Native MQTT routing scenarios](evidence/appwrite-push-routing-2026-11-20.md)

## K25 · Live social credential exchange

Use real Google and Apple credentials with the selected backend. Verify the
exchange, native/browser callbacks, and sign-out. Confirm that the SDK keeps
provider credentials and backend session tokens distinct.
[Social login changelog](../../extensions/social_login/CHANGELOG.md)

## K26 and K29 · Location and deep links on iOS

- **K26:** Verify typed location failures when permission or service
  availability changes between support checks and calls. Exercise mid-run
  permission revocation on a build that leaves the process alive.
- **K29:** Verify custom-scheme links on iOS in cold-start and warm delivery.
  Include matching and rejected host/path inputs.

[Android location and deep-link evidence](evidence/geolocation-deeplink-device-2026-11-22.md)

## Deferred work and limits

| Item | Trigger or boundary |
| --- | --- |
| K17 · Storage recovery cost | Revisit incremental checkpoints when an app measures a large-store migration bottleneck. Import recovery restores the journaled values and cannot detect an unrelated writer. [Decision](evidence/product-decisions-2026-11-22.md) |
| K19 · Token deadline | SDK-backed providers enforce deadlines only where the vendor SDK offers cancellation. [Contract decision](evidence/contract-decisions-2026-11-21.md) |
| K21 · Registry download UX | Retry and cancellation UX for slow registry requests remain optional follow-up work. [Store changelog](../../packages/kiln_store/CHANGELOG.md) |
| K22 · Staging and locking | Revisit full-project staging when measured upgrade cost warrants it. Direct SDK callers own locking across calls. [Installer changelog](../../packages/kiln_extension_sdk/CHANGELOG.md) |
| K24 · Older installs | Migrate saved literal client values to `env:NAME` where appropriate. [Client-values guide](../cli/client-values.md) |
