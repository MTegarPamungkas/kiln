# FCM push delivery acceptance (Android emulator)

Date: 2026-11-23 (Asia/Jakarta). **Emulator**, `emulator-5554`
(`sdk_gphone64_x86_64`, Android 17 / API 37, `google_apis_playstore` image).
No commit or deployment was made.

## What this proves and what it does not

This run closes the "FCM delivery end-to-end with `dev.tegar.appwrite_demo`"
line of K23 **on an emulator**. Per the audit's evidence rules an emulator run
is not physical-device evidence, so K23's device row stays open for a phone.

What it does establish:

- The `appwrite_push` brick's FCM transport receives real messages from the
  Appwrite Messaging API in foreground, and again after the app card is swiped
  out of recents (process gone, Android restarts it from the FCM broadcast).
- A production defect in Appwrite 2.7.2 routing: with more than one push
  provider in a project, a target registered with `providerId: null` is
  **silently not delivered** while the message still reports `sent`,
  `deliveredTotal: 1` and an empty `deliveryErrors`.

## Three separate blockers, in the order they were hit

| # | Symptom | Cause | Resolution |
| --- | --- | --- | --- |
| 1 | Support `push=unavailable`; logcat `SERVICE_VERSION_UPDATE_REQUIRED`, `Google Play services out of date ... Requires 261200000 but found 261136038` | `firebase_messaging` 17.0.1 needs a GMS build newer than the emulator image shipped (26.11.36) | Updated Google Play services from the Play Store to 26.45.64 |
| 2 | Support `supported`, but no target registered for the app package | `dev.tegar.appwrite_demo` was not a registered Android platform in the project | Registered an Android platform with the debug SHA-1 `dd2fdaa16bcc6757e8e53115e4db48aa401341d6` |
| 3 | Support `supported`, target exists, message reports `sent` / `deliveredTotal 1`, **device receives nothing** | Target has `providerId: null` and the project has three push providers, so Appwrite cannot choose one | Re-created the target bound to the FCM provider (`providerId: kilnfcm73359`) — delivery then worked |

Layer 2 is expected configuration. Layer 1 is emulator hygiene. **Layer 3 is a
finding**, described below.

## The routing finding

On the first project (`6afebe9d000e9c351b3e`) three push providers existed:
`kilnclean_mwnx8bq3` and `kilnroute_mwoxkctu` (both `appwrite` type) and
`kilnfcm73359` (`fcm`). A push target created by the Flutter client
(`account.createPushTarget` without `providerId`) is stored with
`providerId: null`. Sending a push message to that user then:

- returns HTTP `201` with `status: processing`,
- later reports `status: sent`, `deliveredTotal: 1`, `deliveryErrors: []`,
- and produces **no** delivery: `GET /messaging/messages/{id}/targets` returns
  `total: 0`, and the device log shows no FCM receive.

Binding the same token to a target with `providerId=<fcm provider>` makes the
same message arrive within seconds. So the success counters describe message
acceptance, not delivery, when routing is ambiguous.

A clean second project (`6b034e63002df33d3aab`, single push provider
`kilnfcmclean`) delivered to a `providerId: null` target on the first try. This
isolates the trigger to **the number of push providers**, not to the Kiln code.

### Why the Kiln side cannot fix it today

`AppwritePushTransport.initialize()` registers the FCM token through
`PushTargets.register(token: ...)` with no provider argument
(`extensions/appwrite_push/brick/__brick__/lib/extensions/appwrite_push/appwrite_push_transport.dart`),
and `AppwritePushModule` exposes no provider option. The `PushTargets` contract
has an optional `providerId` for `register`, but the transport never sets it.
An application therefore cannot say which provider its token belongs to, so any
project with more than one push provider is exposed to the silent no-op.

Candidate directions (not implemented, owner decision):

1. Add an `AppwritePushModule(providerId: ...)` option that flows into
   `register(providerId: ...)`, so a client can be explicit.
2. Document in the extension that a project must keep exactly one push provider
   unless the app passes a provider id.
3. Treat the Appwrite behaviour as an upstream defect and report it.

## Results by scenario

Project `6b034e63002df33d3aab`, provider `kilnfcmclean` (enabled, FCM, service
account), user `kilnfcmcleanuser`, package `dev.tegar.appwrite_demo`.

| Scenario | Evidence |
| --- | --- |
| Foreground receive | `KILNPROBE foreground title=Kiln clean probe data={run: clean-1}`; UI text `received: Kiln clean probe`; server `sent`, `delivered 1`, `deliveryErrors []` |
| Swipe-away from recents | Before send `pidof dev.tegar.appwrite_demo` empty; after send process restarted `Start proc ... for broadcast FlutterFirebaseMessagingReceiver`, `FLTFireMsgService: FlutterFirebaseMessagingBackgroundService started!`; tray shows `Kiln clean swipe` / `Swiped away, single provider` |
| Tap on tray notification | `topResumedActivity=dev.tegar.appwrite_demo/dev.kiln.fcm_probe.MainActivity` — app opens |

On the first project the equivalent foreground message only arrived after the
target was bound to `kilnfcm73359`:
`KILNPROBE foreground title=Kiln probe 6 data={run: fcm-probe-6}`.

## Observed secondary issues (not blockers)

- `FirebaseMessaging: Missing Default Notification Channel metadata in
  AndroidManifest. Default value will be used.` — background notifications land
  on `fcm_fallback_notification_channel`. The `appwrite_push` background handler
  declares its own `appwrite_push` channel for **data-only** pushes, but
  notification-payload pushes are rendered by the platform on the fallback
  channel because the generated manifest sets no default channel.
- `FirebaseMessaging: Unable to log event: analytics library is missing` —
  harmless; Firebase Analytics is not a dependency of the probe.
- Tapping a notification opens the app but the tap payload is not surfaced: the
  transport subscribes to `FirebaseMessaging.onMessage` only, with no
  `onMessageOpenedApp` / `getInitialMessage` hand-off, so an app cannot route on
  the notification that launched it.

## How it was driven

```bash
# GMS update happened in the Play Store UI on the emulator (no adb path).
adb devices -l
adb install -r .dart_tool/fcm_probe/build/app/outputs/flutter-apk/app-debug.apk
adb shell pm grant dev.tegar.appwrite_demo android.permission.POST_NOTIFICATIONS
adb shell am start -n dev.tegar.appwrite_demo/dev.kiln.fcm_probe.MainActivity
adb logcat -d | grep KILNPROBE
# swipe: input keyevent KEYCODE_APP_SWITCH, then input swipe 540 1400 540 150 80
```

The probe (`tool/e2e/fcm_probe_main.dart.tmpl` rendered into
`.dart_tool/fcm_probe`) signs in a fixed probe user, calls
`AppwritePushTransport.initialize()` and logs `KILNPROBE` lines. Messages were
sent through `POST /v1/messaging/messages/push` with `users: [<user id>]` and
`draft: false`.

## Not covered

- Physical Android device (this is emulator-only).
- iOS/APNs.
- MQTT broker path (`appwrite_push_native`), covered by the earlier device push
  report.
- Long-idle/Doze delivery, reboot recovery, repeated delivery.
- Token rotation re-registration against the provider-bound target.

## Temporary resources (removed after the run)

First project `6afebe9d000e9c351b3e`: platform `kilnfcmplat77809010`, FCM
provider `kilnfcm73359`, user `kilnfcmuser1795373460`, its push/email targets,
and the seven probe messages were all deleted (`204` each). The pre-existing
`kilnclean_*` and `kilnroute_*` providers/platforms/users and the owner's own
account were left untouched.

Second project `6b034e63002df33d3aab` (`Kiln FCM Clean`): the platform, FCM
provider, user, targets, three probe messages and the `kiln-fcm-probe` API key
were deleted (`204` each); the console shows the project with no providers.

The local credential file `.dart_tool/fcm_clean.env` and the request/response
scratch JSON under `.dart_tool/` were deleted. The owner may delete the empty
`Kiln FCM Clean` project from the console if it is not wanted.
