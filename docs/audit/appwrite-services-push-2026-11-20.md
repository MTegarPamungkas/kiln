# Appwrite services and push acceptance

Date: 2026-11-20 (Asia/Jakarta). No commit or deployment was made.

## Environment and results

The generated Kiln application ran on a Pixel 10a Android emulator (API 37)
and Chrome on Windows against the self-hosted Appwrite project. The host-only
helper used memory, with no extra database. Actual Appwrite calls used a unique
temporary user, database, tables and bucket. The API key stayed on the host.

| Area | Android | Web |
| --- | --- | --- |
| Database, realtime, storage and push targets | 26 passed | 26 passed |
| Native MQTT foreground push | 8 passed | Unsupported by this extension |
| Native MQTT background receipt and logout | 7 passed | Not tested |

The 67 assertions cover row CRUD, missing rows, filters, limits, ordering,
cursors, offsets, permission failures, realtime snapshots/update/delete,
upload metadata/progress, exact download bytes, deleted-file failures,
replacement bytes at the same file ID, a chunked upload over 5 MiB,
explicit rejection of unsupported expiry, push-target lifecycle and logged-out
database denial. Synthetic push-target tests establish registration only.

Realtime mutations happened after the initial reconciliation window, so the
update/delete results establish WebSocket event delivery.

Actual push used an Appwrite messaging provider and the TLS MQTT endpoint
`mqtts://push.tegardev.id:8883`. The TLS certificate was valid for that hostname.
Messages were scoped to the temporary user. Both foreground and background
callbacks received the expected title, body, route and run marker, and logout
unsubscribed the transport. The server recorded background delivery as `sent`
with one delivery and no delivery errors.

## Corrections made

- Row cursors were silently ignored. The query mapper now emits `cursorAfter`
  and rejects empty cursors or mixed cursor/offset pagination.
- Chrome reused cached binary bytes after file deletion. Client requests now
  set `Cache-Control: no-cache, no-store`. Live deletion and same-ID replacement
  checks pass. This also makes other client reads request revalidation.
- Native push callbacks could outlive a pending subscription during logout.
  Session changes now invalidate their generation immediately; a regression
  verifies that a late callback cannot forward a message or revive a subscription.
- Added separate service and native-push fixture modes and a host coordinator
  that provisions isolated resources and records ownership without credentials.

Rendered Appwrite and native-push analysis/tests passed. Live probes were
coordinated through the fixture and host helper; the complete one-command
coordinator has not yet been rerun from a clean fixture end to end.

Final local verification passed: workspace `dart analyze`, both affected
rendered extension suites, all 160 CLI tests, extension lint/golden checks,
bundle and registry consistency, catalog/document/version checks and
`git diff --check`. The local CLI executable was rebuilt and its `version`
command returned `kiln 0.1.1` / `kiln_core 0.1.1`.

## Remaining acceptance work

### Subsequent Android swipe-away check

The app card was physically swiped upward out of Android's recent-apps view
before each message was sent; pressing Home was not used as the acceptance step.
With `Push.setForeground(false)`, the original process stopped and Android
started a background process, but no notification appeared in the 82-second
observation window. This does not establish that scheduled delivery never works.

With `Push.setForeground(true)` and the two foreground-service permissions in
the disposable fixture, the card was removed again. The service and process
remained running. A new message sent after removal immediately produced a system
notification titled `Kiln after swipe`, observed both in Android's notification
records and on the emulator screen. Appwrite recorded one delivery without
errors. This proves swipe-away delivery with an active foreground service on
this emulator; it does not prove immediate delivery with the process absent.

Foreground mode was enabled only in the disposable fixture. Applications can
opt into the SDK method while visible and declare `FOREGROUND_SERVICE` and
`FOREGROUND_SERVICE_REMOTE_MESSAGING`. It displays an ongoing connection
notification. See the official [closed-app delivery documentation](https://appwrite.io/docs/products/messaging/appwrite-push).

After inspection, the owner requested removal of the battery-consuming test.
The disposable app was uninstalled, all owned preview resources were deleted,
the helper stopped and ADB forwarding removed. Cleanup succeeded; the records
are `.dart_tool/appwrite_swipe_ownership.json` and `appwrite_swipe_result.json`.

### Still open

### Clean reinstall: swipe-away without a foreground service

A subsequent run uninstalled the fixture, cleared its Flutter build cache and
installed it again with `Push.setForeground(false)`. The fixture's foreground
permissions were removed; a generic `FOREGROUND_SERVICE` permission still merged
from a transitive plugin, but `FOREGROUND_SERVICE_REMOTE_MESSAGING` was absent.
No foreground service or ongoing connection notification was present.

After a successful subscription, the app card was physically swiped out of
recents. PID 12925 disappeared, and no app process was present immediately
before sending. Only then was a new message sent. Android started PID 13088
and displayed `Kiln clean install test` / `Native push without a foreground
service.` in the system tray, without opening the app. Appwrite recorded one
delivery and no errors. This establishes native scheduled/restart delivery on
this emulator without foreground mode. It does not establish that reinstalling
alone caused the earlier failure to disappear: the build cache was also reset.

The earlier 82-second failure remains valid evidence for that earlier state,
but must not be used to claim that native Appwrite requires a foreground
service. Physical-device, long-idle/Doze, reboot and repeated-delivery checks
remain open. Exact temporary resource ownership and cleanup state are recorded
in `.dart_tool/appwrite_clean_swipe_ownership.json` and
`appwrite_clean_swipe_result.json`. The fixture remains installed for inspection.

Update 2026-11-20/21: physical-device delivery, tap routing (warm,
terminated-process launch, signed-out tap/login/return), force-stop recovery,
offline replay and a forced-deep-idle run are recorded in the
[push routing report](appwrite-push-routing-2026-11-20.md). That run did not
observe Doze deferral, so long-idle behaviour stays open, and reboot plus
repeated-delivery remain unverified.

### Remaining scenarios

1. Google OAuth is now enabled. The server originally generated an HTTP Google
   callback while Google's client configuration allowed HTTPS. The API sits
   behind Cloudflare Tunnel (`http://localhost:80`) and Traefik. Traefik's HTTP
   entrypoint now trusts forwarded headers only from loopback and the observed
   Docker gateway addresses; `_APP_OPTIONS_FORCE_HTTPS=enabled` is set on the API.
   Public health returns 200, an unauthenticated POST returns the expected 401,
   and the OAuth endpoint redirects to Google with the HTTPS callback. Port 80
   remains bound to loopback; no port reassignment was needed. Server config
   backups were retained before editing. Google's authorized redirect URI must
   match `https://appwrite.tegardev.id/v1/account/sessions/oauth2/callback/google/6afebe9d000e9c351b3e`.
   Subsequent real Google OAuth browser acceptance passed: the owner completed
   Google's sign-in, and Kiln established an Appwrite session. After a full page
   reload, the session was restored, the server account matched the local user,
   and TokenProvider returned a nonempty Appwrite JWT (never logged). Logout
   cleared the local session and the real account endpoint rejected access with
   401. A further page reload remained signed out. Google itself remains signed
   in; Appwrite logout is not Google account logout. No user account was deleted.

   The initial popup cancellation check failed: closing the Google popup left the probe
   waiting with disabled controls. The installed flutter_web_auth_2 5.1.0 web
   implementation polls callback storage/messages until its default five-minute
   timeout and does not detect popup closure. Appwrite delegates to that method.
   The existing SocialAuth timeout bounded post-callback user polling, not the
   interactive browser Future. This was corrected by a conditional web launcher
   that owns the popup, detects closure, closes abandoned attempts after five
   minutes, and removes listeners/timers. Logout/disposal also cancel its popup.
   Callback origin, source window, path and a random per-attempt identifier
   must match; callbacks from replaced attempts are ignored. Provider errors
   remain failures, and native platforms continue using Appwrite's SDK.
   Actual browser verification then passed: closing the Google popup returned
   cancellation with retry enabled, retry opened a new popup, and after the owner
   completed Google consent the account and JWT were verified again. Regression
   tests cover closure/retry, replacement and stale callbacks, explicit cancel,
   deadline cleanup, popup blocking and provider failures. Closing the browser
   cannot roll back a server session created before closure.

   Android Google OAuth subsequently exposed a separate defect: explicitly
   passing `appwrite-callback-<PROJECT_ID>://` as the native success URL caused
   `Invalid OAuth2 Response. Key and Secret not available`. The native launcher
   now omits both redirect arguments, as required by the Flutter SDK's native
   flow. Unsupported native custom redirects fail before browser launch.
   Regression tests record the SDK arguments and reject custom native URLs.

   Actual Android emulator acceptance passed after this correction: Google
   account selection/consent returned to the app, server identity and JWT were
   verified, closing a second OAuth browser returned cancellation with retry
   available, and a rebuilt APK restored the session after the original app
   process was stopped. Logout then cleared local state and the account API
   returned 401; another process restart remained signed out. The fixture was
   left installed and open in the signed-out state. Physical-device and Apple
   OAuth acceptance remain deferred. No personal Google account was deleted.

   Cancellation-fix validation: rendered Appwrite analysis/tests, workspace
   analysis, explicit web-launcher analysis, extension lint/goldens, bundle and
   registry checks passed. Catalog docs were regenerated for the direct `web`
   dependency. The CLI run had 159 passes and one 30-second timeout in the
   build-variable setup test under concurrent load; that exact test passed on
   isolated rerun. The CLI executable was rebuilt. No commit was made.
2. Notification-tray presentation and swipe-away delivery have now been observed
   both with a foreground service and without one after a clean reinstall.
   Repeat scheduled delivery on a physical Android device, then test notification taps,
   terminated-app launch, battery restrictions and permission denial. Do not
   equate a received callback with a displayed notification.
3. Browser push needs a supported browser transport and reachable secure
   WebSocket broker. Handshake probes on port 443 at `/` and `/mqtt` timed out;
   the DNS-only TCP 8883 endpoint establishes native MQTT connectivity only.
4. iOS/macOS execution remains deferred. Existing platform code is not evidence
   of APNs delivery or device acceptance.
5. Functions, SMTP flows and the separate FCM-based push extension still need
   their own live tests. These results cover the exercised contracts only.

Credential-free detailed reports and ownership records are stored under
`.dart_tool/appwrite_services_push_result.json` and the ownership journal.
All temporary users, databases, buckets, platforms, providers and messages from
this run were deleted successfully. The helper was stopped and ADB forwarding
removed; the emulator was left running.
