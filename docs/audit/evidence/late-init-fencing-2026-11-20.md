# Late-initialization fencing after bootstrap disposal

Date: 2026-11-20 (Asia/Jakarta). Addresses K10/K13 in
[findings](../findings.md) and the status board in [current-status](../current-status.md).

## The hazard

`KilnBootstrap` awaits `module.ready(registry)` under `Future.timeout`, and a
timeout does not cancel the operation: the future keeps running while the
bootstrap failure path calls `lifecycle.dispose()`, which disposes every module
already registered. A module that resumed after the timeout could therefore:

- attach a listener or timer that outlives the application,
- publish into a stream or controller that was already closed,
- write a session into a disposed `SessionController`, or
- register a process-wide handler after shutdown.

`SupportRegistry.record` already ignores late results and `LifecycleController`
swallows callback errors, so the remaining work is cooperative: each owner must
check disposal between awaits and refuse to attach resources afterwards.

## What was audited

Every module with an asynchronous `ready()` plus the component that owns the
async work: analytics, appwrite, appwrite_push, appwrite_push_native,
connectivity, crash_report, deep_link, env, firebase, flavors, go_router, l10n,
notifications, remote_config, rest_auth, secure_storage, social_login, storage,
supabase and theme. Modules whose `ready()` is synchronous (env, flavors,
go_router, permission) have no window to fence.

## Findings and fixes

| Owner | Hazard | Fix |
| --- | --- | --- |
| `DeviceNetworkMonitor` (connectivity) | `start()` awaited the platform check, then registered the listener and added to its own stream even when disposed: leaked subscription plus `StateError: Cannot add event after closing`. | `_disposed` fence after the await and in `_emit`; `dispose()` is idempotent and closes once. |
| `FirebaseSessionBridge` (firebase) | `start()` after `dispose()` re-subscribed and wrote into the disposed application session. | `_disposed` set by `dispose()`; late `start()` is a no-op. |
| `FirebaseModule.ready` | Configured the emulator and started the bridge after disposal during `Firebase.initializeApp`. | Disposal checks between the awaits; late support records suppressed. |
| `AppwritePushTransport` (appwrite_push) | Listeners for token rotation and foreground messages were created after `getToken()`/`register()` even when disposed during them. | Disposal checks after each await and before both listeners. |
| `AppwritePushModule.ready` | Registered the global `onBackgroundMessage` handler after disposal. | Disposal check before the global registration. |
| `RestSessionBridge` (rest_auth) | Not disposed at all; a late `start()` mirrored auth changes into a closed controller. | `_disposed` fence plus lifecycle-owned disposal in `register()`. |
| `SocialSignOutListener` (social_login) | Not disposed; a late `start()` could sign out of Google after shutdown. | `_disposed` fence plus lifecycle-owned disposal. |
| `SupabaseLinkHandler` (supabase) | Disposal during the initial callback still attached a `DeepLinks` listener; sessions were delivered to a closed app. | `_disposed` fence after the initial callback, in `_complete`, and idempotent `dispose()`; lifecycle-owned disposal. |
| `SupabaseSessionBridge` (supabase) | Late `start()` re-attached to a disposed controller; nothing disposed it. | `_disposed` fence and lifecycle-owned disposal. |
| `RemoteConfigModule.ready` | Activated a fetched snapshot on a client that `dispose()` had already closed. | Disposal check after the fetch; idempotent `dispose()`. |
| `DeviceNotifications.initialize` (notifications) | Attached the tap hub after a disposal that happened during plugin initialization. | Disposal checks before attaching the hub and before marking initialized; idempotent `dispose()`. |

Already correct before this pass, and re-checked: analytics (consent/setup
fencing), crash_report, appwrite (`AppwriteSessionBridge` revision and disposal),
deep_link (`DeviceDeepLinks`), l10n and theme (controllers), notifications tap
hub, appwrite_push_native transport, rest_auth's own auth client.

Deliberately unchanged: `storage`'s migration and `secure_storage`'s first-run
wipe are one-shot writes with no listeners; they are bounded, idempotent on the
next start and cannot hold an open handle. `BiometricAppLock.initialize` is
lazy (not called from bootstrap). Modules with synchronous `ready()` cannot hit
this window.

## Tests

Added regressions that make the race deterministic with a gated platform call:

- `connectivity`: dispose during the first status check leaves no listener and
  publishes nothing (`device_network_monitor_test.dart`).
- `firebase`: `start()` after `dispose()` does not subscribe
  (`firebase_session_bridge_test.dart`).
- `rest_auth`: `start()` after `dispose()` leaves `SessionController` untouched
  (`rest_session_bridge_test.dart`).
- `social_login`: `start()` after `dispose()` does not sign out of Google
  (`social_sign_out_listener_test.dart`).
- `supabase`: disposal during the initial PKCE exchange attaches nothing and
  delivers no session (`supabase_link_handler_test.dart`), and a late bridge
  `start()` does not seed a session (`supabase_session_bridge_test.dart`).

The timestamped-free race is still a device-level property: the tests prove the
fence, not that a real plugin's teardown is instant.

## Verification

Each changed extension was rendered on its own and passed analysis and its full
rendered test suite: connectivity, firebase, rest_auth, social_login, supabase,
remote_config, appwrite_push and notifications. All 34 rendered golden snapshots
match, manifest/module metadata and version checks pass, documentation links are
consistent, root `dart analyze` reports no issues, and the bundle, registry and
catalog were regenerated.

The first full `kiln_cli` run failed one setup test while `dart analyze` was
competing for the machine; that file then passed alone (21 tests) and the full
suite passed 160/160 on the rerun. The audit's earlier note about the same test
timing out under concurrent load still applies, so CLI results should be taken
from a quiet run.

## Remaining

- A timed-out module can still complete server-side work (a sign-in, a fetch) and
  the result is dropped at the fence; there is no cancellation token threaded
  through plugin calls, and `Future.timeout` still cannot cancel them.
- `BiometricAppLock.initialize` remains lazy and unfenced; it needs the same
  treatment if a module ever calls it from `ready()`.
- The Firebase/appwrite_push fences are covered by analysis and code review only:
  their platform calls are static (`FirebaseMessaging`, `Firebase.initializeApp`),
  so no unit test drives the interleaving here.
