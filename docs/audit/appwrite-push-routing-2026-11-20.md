# Appwrite push routing continuation - 2026-11-20

## Implementation

The optional core `PushNotificationOpens` interface exposes generic
`NotificationTap` events without changing the existing `PushTransport` contract.
The native Appwrite transport maps its existing `opened` stream to JSON route
payloads, retaining launch-tap replay for the first subscriber. go_router listens
automatically and cancels its own listener on disposal. Receiving a foreground
message does not navigate; only a tap does.

Route payloads must resolve to local paths. Query parameters and fragments are
preserved. External authorities, backslashes, control characters, encoded
separators and traversal are rejected. Validation examines the original path
before Dart URI normalization can remove encoded dot segments.

## Verified locally

- kiln_core: 180 tests passed during this continuation.
- Rendered go_router analysis and tests passed, including a push tap received
  before authentication, sign-in redirection and return to the requested route
  with its query preserved.
- Rendered native Appwrite push analysis and tests passed, including replay of
  initial notification data through the generic interface.
- The route validation regression initially caught encoded traversal bypassing
  the check; the correction and final suite passed.

Logs are ignored files under `.dart_tool/*push_routes*`.

## Android acceptance and limitation

Superseded for the emulator state: the physical-device section later in this file
establishes the three tap cases and a successful subscription. The text below
records what the emulator run did and did not prove at the time.

Fixture: `tool/appwrite_platform_probe.dart --routing`, with the minimal UI in
`tool/e2e/appwrite_push_routing_probe.dart.template`. Device: Pixel_10a emulator,
`emulator-5554`. Test package: `dev.kiln.routing.e2e_appwrite`. The test app was
uninstalled and installed again, then granted notification permission. Future
native changes must also use uninstall/install before acceptance.

The in-memory loopback fixture supplies a disposable Appwrite account without
embedding its password or a server API key in generated source. Login eventually
succeeded after a failed attempt. Later subscription attempts reported failure
against `mqtts://push.tegardev.id:8883`. The Appwrite message API accepted a probe
and reported `sent`, one delivery and no delivery errors, but no matching Android
notification appeared. This is not proof of device receipt or navigation.

Warm notification taps, real terminated-process launch taps and the signed-out
tap/login/return flow therefore remain unverified on the emulator. The previous
swipe-away delivery evidence remains a separate run; it does not establish tap
routing. Do not mark these cases passed based on unit tests or server delivery
counts. No fake local notification was substituted for MQTT delivery.

## Next acceptance run

1. Render and clean-install the routing probe; start the in-memory fixture and
   reverse its loopback port to the emulator.
2. Sign in and confirm a current successful subscription. Background the app,
   send a unique route payload, then tap the actual Android notification.
3. Verify the displayed route and query, then repeat after removing the app from
   recents and confirm whether the process was actually terminated.
4. Tap a pending notification while signed out; verify sign-in followed by the
   original destination. Record device and server evidence separately.

Also assess whether restored-session bootstrap should wait for MQTT subscription:
the current module awaits transport start, so an unavailable broker can delay
router initialization. This behavior has not been changed in this pass.

No commit or publication was made.

## Final checks and cleanup

Manifest/module metadata, documentation links, bundle consistency and registry
consistency passed. The catalog was regenerated and the local CLI executable was
rebuilt. Both probe messages, the temporary Android platform, messaging provider
and user were deleted with HTTP 204 responses; the credential-free ownership
journal is empty. The loopback fixture was closed and its ADB reverse removed.
The emulator remains running. A new live run needs a fresh disposable fixture.

## Google-account retry after emulator network repair

The routing probe now offers Google OAuth, including on its session-restoration
screen. Its generator installs the project callback activity and labels the app
`Kiln Push Routing`. Native callback changes were tested after uninstall/install.
The generated probe builds successfully. Whole-fixture analysis also reports
unrelated Flutter scaffold issues (missing flutter_lints and the default MyApp
widget test); it must not be reported as a clean analysis result.

The next run initially failed DNS resolution inside Android. Restarting Pixel_10a
without loading a snapshot and with explicit DNS servers `1.1.1.1,8.8.8.8`
restored resolution and ping to Appwrite and Google. Google account selection,
returning-user consent and callback completed, and the routing app displayed Home.
Its latest status was still `Push subscription failed`. A TCP connection attempt
from Android to `push.tegardev.id:8883` timed out. This failure also occurs with
the real Google account, so a disposable account alone does not explain it.

A message targeting that Google account was accepted by Appwrite with status
`sent`, one delivery and no delivery errors. No matching Android notification
was observed; warm/cold tap routing remains unverified. Investigate broker
reachability/listener/firewall next, without confusing server publish status
with device receipt. The app remains signed in for the owner's testing.

Unlike the earlier completed cleanup, this latest retry intentionally leaves its
in-memory fixture and temporary provider/platform resources active. Their exact
ownership is recorded in `.dart_tool/appwrite_routing_ownership.json`. Never delete
the Google user as part of temporary-resource cleanup.

## Physical-device acceptance (21:33-21:50 Asia/Jakarta)

The three outstanding tap cases now pass on the owner's phone, superseding the
"unverified" statements above. Device `c7d2692b`, M2007J20CG (`surya`), Android 13
(SDK 33, arm64). The installed fixture build carried `lastUpdateTime`
2026-11-20 19:40:48, matching the built `app-debug.apk` (19:40:35), so the
identity-display UI was under test; app data was preserved from the 19:36:39
uninstall/install.

Account: the run-owned disposable user `kilnroute_mwoxkctu`
(`kilnroute_mwoxkctu@example.test`), confirmed by `user:<id>` in every report and
by an Appwrite user lookup returning status true. Its password was reset through
the server API so the in-app temporary-account button could be used; no personal
Google account was modified. No credential reached tracked source, the ownership
journal or any log: the generated disposable password lives only in the ignored
fixture state file (`<state-dir>/password.txt`) so the probe can sign in. The MQTT
provider `kilnroute_mwoxkctu` and the temporary Android platform already existed
from the earlier retry.

Fixture host: a loopback HTTP endpoint on `127.0.0.1:8768` (reached from the phone
through `adb reverse tcp:8768 tcp:8768`) served `/fixture` and appended `/report`
bodies to a file, holding the Appwrite key in memory only. The earlier retry used
an ad-hoc Node REPL for this role, so the host was rewritten as the committed
[`tool/e2e/push_routing_host.mjs`](../../tool/e2e/push_routing_host.mjs) with its
state under `.dart_tool/push_routing_host/`. It reads configuration and credentials
from the environment and never logs them.

### Subscription

`Push subscription failed` did not reproduce. Authenticated sign-in reported
`subscribed` within about 0.6 s, and every later message was delivered with
`status: sent`, `deliveredTotal: 1` and no delivery errors. The earlier failures
are therefore broker/network reachability from the device at that time, not a
code defect. No retry logic was added.

### Case 1 - tap with the process alive

Message `kilnroute_msg_mwp3419u` (`Kiln warm tap 20261120-2145`) was delivered
while the app was backgrounded: PID 30450 stayed alive and the launcher was the
resumed activity. Android posted the notification on channel `appwrite-push` with
a `startActivity` content intent. Tapping it navigated to the reported route
`/orders/42?tab=phone`, and the app displayed `Order 42` with that URI, the
account email and user ID. Query preserved.

### Case 2 - notification launching a terminated process

Message `kilnroute_msg_mwp3949k` (`Kiln cold launch 2144`) was delivered to the
live process, then the process was terminated with `am kill` and verified absent
(`pidof` empty, no `kiln.routing` entry in `ps -A`) while the notification
remained posted. Tapping it started a new process (PID 31581) and the bootstrap
`ready` report already showed `/orders/77?tab=closed`; the restored session
displayed the same account and the `Order 77` screen. This is launch-tap replay
through the real content intent, not a fake launch.

### Case 3 - protected destination while signed out

Message `kilnroute_msg_mwp3arak` (`Kiln signed-out tap 2145`, route
`/orders/42?tab=signed-out`) was delivered while signed in. The app was then
signed out in-app, which reported `/sign-in?returnTo=%2Forders%2F77%3Ftab%3Dclosed`
and unsubscribed the transport; the notification stayed pending. Backgrounding
the app and tapping the pending notification navigated to
`/orders/42?tab=signed-out`, which the guard redirected to
`/sign-in?returnTo=%2Forders%2F42%3Ftab%3Dsigned-out` (visible on screen).
Signing in with the temporary account then reported `subscribed` at
`/orders/42?tab=signed-out` under `user:kilnroute_mwoxkctu`, and the screen showed
`Order 42`. The original route and query survived the sign-in detour.

### Revalidation with the committed host

The run was repeated through `tool/e2e/push_routing_host.mjs` to prove the committed
harness, not just the ad-hoc one. The probe was force-stopped and relaunched against
the new host; it restored the session (`ready` report carried
`user:kilnroute_mwoxkctu`), and message `kilnroute_msg_mwp3hnhq`
(`Kiln tool host tap 2150`, route `/orders/9?tab=tool`) was delivered and tapped,
navigating to `/orders/9?tab=tool`. The screenshots `15` and `16` cover this pass.

### Hardening pass (22:00-22:35)

The remaining gaps from the acceptance above were addressed with code, tests and
device checks rather than more manual taps.

Implementation (`appwrite_push_native` 0.1.0 to 0.2.0, `kiln_core` 0.1.1):

- `start()` is bounded by `subscribeTimeout` (10 s). An unacknowledged
  subscription is reported and retried instead of stalling bootstrap.
- A failed subscription is retried with exponential backoff (`retryBaseDelay`
  doubling to `retryMaxDelay`), and `retryNow()` skips the wait.
- Repeated taps on the same notification are deduplicated inside
  `tapDedupeWindow` (2 s) by Messaging id or topic plus payload, covering a double
  tap and the SDK reporting a launch tap twice. `duplicateTapsIgnored` counts
  them; `AppwritePushOpened` now carries the Messaging `messageId`.
- New optional core capability `PushDeliveryControls` with `PushDeliveryStatus`:
  `status()`, `setForeground()`, `requestExactAlarms()` and
  `requestIgnoreBatteryOptimizations()`, forwarded to the SDK driver when it
  implements them.
- The installer adds the iOS `remote-notification` background mode when the
  `background` prompt is on, and the opt-in `background_reliability` prompt
  declares the Android exact-alarm and battery-optimisation permissions.

Device evidence, same phone, rebuilt and reinstalled probe:

| Check | Result |
| --- | --- |
| Force-stop then send | No notification and `deliveredTotal 0` initially; after reopening the app a new message arrived and its tap reached `/orders/52?tab=recovered`. |
| No network then send | Message sent with no default network produced no notification; after Wi-Fi/data came back the notification was posted within about 30 s from broker replay, and its tap reached `/orders/53?tab=offline`. While offline the server still reported `deliveredTotal 1`, confirming server counts are not device receipt. |
| Forced deep idle | `dumpsys deviceidle force-idle` reached `mState=IDLE`; a message sent then was posted within 5 s, twice in a row. No deferral was observed, so this run does not demonstrate Doze deferral either way. |
| Broker that never acknowledges | A silent TCP endpoint (`mqtts://127.0.0.1:8889` through `adb reverse`) still produced a `ready` report 14.6 s after launch, with `retry:1`, instead of a hung bootstrap. After restoring the real endpoint and relaunching, `retry:0`. |
| Delivery controls | Probe reported `exactAlarms:false`, `batteryExempt:false`, `foregroundService:false`, `bestEffort:true`, `backgroundRestricted:false`; `retryNow()` reported `retried-subscribed`. |
| Duplicate taps | Covered by rendered transport tests; every device report showed `dup:0`. |

Rendered `appwrite_push_native` analysis and its 17 transport tests pass, as do
the extension manifest/render tests, all 180 `kiln_core` tests, metadata and
version checks, documentation checks and the regenerated bundle/registry/catalog.
Workspace `dart analyze` reports no issues.

The iOS and Android native setup was verified through the installer plan itself
rather than a device: with `background` on, the plan writes
`UIBackgroundModes = [remote-notification]` into `ios/Runner/Info.plist`; adding
`background_reliability` also emits `SCHEDULE_EXACT_ALARM` and
`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` in the Android manifest.

Not addressed by code, with reasons: notification action buttons cannot be added
without replacing the SDK's own notification builder (documented as a limitation,
with one notification per action as the supported alternative); a locked-screen
tap needs the owner's PIN to complete, so it stays a manual procedure; iOS needs
APNs credentials and an Apple device, so only its platform setup is written.

### Method and limits

Taps were injected with `adb shell input tap` on the real, user-visible notification
shade, targeting the genuine `PendingIntent` content intent of the notification
posted by the app; no synthetic notification, broadcast or activity start was
substituted. Only the finger was synthesized. Input on this MIUI build is
occasionally swallowed on the first shade interaction: the recorded runs needed a
shade re-open before the taps registered, so a silent no-op tap must not be read
as app failure.

Still open: a physically repeated tap on one notification (deduplicated in code
and tests, not reproduced on the device), tap with the device locked, notification
action buttons (unsupported by the SDK), Doze deferral (the forced-idle run
delivered immediately instead), long unattended idle, iOS delivery, and OS-initiated
process death other than the verified force-stop/`am kill` cases.

Evidence: device screens are saved as `.dart_tool/push_routing_shots/01..22-*.png`
(ignored by git); the message IDs above identify the server records.

### Bootstrap wait for transport start

Resolved by measurement rather than by changing the module. The module still
awaits `transport.start()`, but the transport bounds the awaited subscribe with
`subscribeTimeout` (10 s) and catches every failure, so bootstrap is capped
instead of following the SDK's own connect timeout. With a broker that accepts
the socket and never acknowledges, the probe reported `ready` 14.6 s after
launch (including Flutter startup) with `retry:1` and a retry already scheduled;
against the real broker the same launch reported `retry:0`. Keeping the await is
therefore safe, and no module change was needed.
