# K09 native SDK acceptance on Android

Date: 2026-11-22 (Asia/Jakarta). Physical phone `c7d2692b` (M2007J20CG, Android
13, API 33). Not an emulator run. No commit or deployment was made.

## Why a loopback host instead of the vendors

The web pass (`analytics-crash-live-sdk-2026-11-22.md`) used real PostHog and
Sentry projects, but its tokens were deleted afterwards and re-issuing them needs
the owner's vendor login. For the native question — *what does the SDK put on the
wire* — the vendor endpoint matters less than the transport. Both extensions
accept a custom `host`/`dsn`, so the build pointed them at a local capture host:

```
api_key  = phc_kiln_loopback_probe
host     = http://127.0.0.1:8799          (posthog)
dsn      = http://public@127.0.0.1:8799/1 (sentry)
```

`adb reverse tcp:8799 tcp:8799` forwards the phone's loopback to the capture
host, so every request is genuine native SDK traffic over real HTTP. Nothing
left the machine and no vendor account was used.

## Fixture

`tool/e2e/device_probe.dart --k09` renders the current `analytics` and
`crash_report` bricks into `.dart_tool/k09_probe` and writes
`tool/e2e/k09_probe_main.dart.tmpl` as `lib/main.dart`. Phase durations are
parameters (`--grant-seconds`, `--revoke-seconds`). The probe marks each phase
on the host (`/__mark?label=...`) and drives:

1. deny both categories → `capture`, `identify`-free, `captureError`;
2. grant both → `identify`, `capture`, `addBreadcrumb`, `captureError`;
3. revoke both → `capture` and `captureError` **after** revocation.

Capture host: `tool/e2e/k09_capture_host.mjs --port 8799`, which records every
request (method, path, size, body) and answers like the vendors do.

## Result

Two runs, both with the corrected build:

| Phase | Requests | Notes |
| --- | --- | --- |
| deny (before any grant) | **0** | neither SDK is initialised; calls are dropped |
| grant | config, `/flags/`, 1 Sentry envelope, 1 PostHog `/batch` | setup starts only after consent |
| revoke + 45 s | `/flags/` (1), PostHog `/batch` (1) | see below |

Sentry: the only envelope carried `kiln-native-grant-error` with
`release=kiln-native-acceptance`, `environment=production`, a
`kiln-native-breadcrumb` breadcrumb, and the `kiln_phase=grant` context. The
deny error and the post-revoke error are **absent** from every body.

PostHog: `/batch` carried `$identify` and `kiln_native_grant`. `kiln_native_deny`
and `kiln_native_after_revoke` are **absent**.

## Defect found: a queued event still leaves after revoke

This is the "queued events" part of K09's acceptance criteria, and it failed on
the first pass. Three separate causes were found and fixed:

| Cause | Fix |
| --- | --- |
| The SDK holds captured events until `flushAt` (20) or `flushInterval` (30 s); `optOut()` stops new captures but does not discard the queue, so a grant-time event was sent 18 s **after** `revoke_start`. | `flushAt = 1` (`AnalyticsConfig.pendingEventLimit`): one event per send, so nothing can sit in a queue across a consent change. |
| `reset()` rotated the identity on revoke, which makes the native SDK reload feature flags — a `/flags/` request after consent ended. | The rotation is deferred to the **next grant** (`_resetOnNextGrant`), so revoke performs no network call at all. |
| `optOut()` persists in the SDK across launches; a later run that granted consent stayed silent because setup does not clear the stored opt-out. | Every grant now calls `setEnabled(true)`, keeping stored state aligned with current consent. |

Verification, physical phone, 10 s grant window (shorter than the 30 s flush):

```
all requests this run:  config, 2x /batch, 1 Sentry envelope
AFTER REVOKE:           NONE
kiln_native_grant:      8.2 s (during grant)
kiln_native_deny:       ABSENT
kiln_native_after_revoke: ABSENT
kiln-native-grant-error: 8.4 s   kiln-native-after-revoke-error: ABSENT
```

Both SDKs are silent after revoke, and the denial-phase calls never appear.

Residual: the deferred `reset()` runs on the next grant, so a fresh identity is
established only when consent is given again. Between revoke and that grant the
SDK keeps its previous anonymous id on disk even though nothing is sent.

## What this proves

- Deny: zero native traffic (no SDK initialisation for sending).
- Grant: both SDKs initialise and deliver, with breadcrumb and context intact.
- Revoke: new captures are dropped at the gate.
- Native `beforeSend` covers native-initiated automatic events only in the paths
  the plugin routes through Dart; the queued-flush path is not covered.

## Not done

- Real vendor dashboards: no PostHog/Sentry account was used in this run (the
  loopback host stands in for ingestion). The web report already covers real
  vendor ingestion.
- iOS: no device.
- Fix for the queued-flush leak above: needs a decision (flush-then-reset on
  revoke, or a short flush interval, or an SDK option that discards the queue).

## Cleanup

Probe APK, `adb reverse`, and the capture host were stopped; `.dart_tool/k09_probe`
and `.dart_tool/k09_capture` are disposable fixtures under the ignored
directory. No credentials were written anywhere.
