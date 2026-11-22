# Analytics and crash reporting against live PostHog and Sentry

Date: 2026-11-22 (Asia/Jakarta). Closes the live-traffic remainder of K09: the
module suites and transport filters were already covered by fakes, but no run
had shown what the real SDKs put on the wire under consent deny/grant/revoke.
No commit or deployment was made.

Environment: Windows, Flutter 3.47.9 / Dart 3.13.7, rendered as a release web
build and driven in the Qoder in-app browser (Chromium 150 via Electron 43.8.4).

## Resources

Disposable acceptance resources, created for this run only. The project tokens
are write-only client keys; they are not server credentials.

| Vendor | Resource | Used for |
| --- | --- | --- |
| PostHog | project `758963`, US Cloud | analytics ingestion |
| Sentry | org `tegar-dev`, project `flutter` (`FLUTTER-1`) | crash ingestion |

The credentials lived only in `.dart_tool/acceptance.env` and were passed to the
build with `--dart-define`; the file was deleted after the run. No token appears
in this report, the source tree or `kiln.yaml`.

## Fixture

A real generated app, not a hand-written harness, so the installer path is part
of the evidence:

```bash
dart run packages/kiln_cli/bin/kiln.dart create kiln_k09 --org dev.kiln \
  --core-path "<repo>/packages/kiln_core" \
  --with analytics,crash_report \
  --answer api_key=env:KILN_POSTHOG_KEY \
  --answer host=https://us.i.posthog.com \
  --answer dsn=env:KILN_SENTRY_DSN \
  --answer release=kiln-acceptance \
  --platforms android,ios,web \
  --output .dart_tool/k09 --yes

flutter build web --release --dart-define=KILN_K09_PROBE=true \
  --dart-define=KILN_POSTHOG_KEY="<key>" \
  --dart-define=KILN_SENTRY_DSN="<dsn>"
python -m http.server 8091 --bind 127.0.0.1 --directory build/web
```

Two fixture-only additions under `.dart_tool/`:

- `lib/k09_probe.dart` runs a fixed timeline and logs `[K09] phase=...` lines,
  so console output and vendor dashboards can be correlated.
- `web/index.html` initializes `posthog-js` **on Dart request**
  (`window.kilnInitPosthog`). On web, `posthog_flutter` assumes the host page
  owns `posthog-js`; without this bridge the extension's web build is a silent
  no-op. The bridge is only called after analytics consent is granted.

## Timeline

| Step | Action | Support state (`SupportRegistry`) |
| --- | --- | --- |
| 1 | both categories denied; `captureEvent` + `reportError` | `notConfigured` (waiting for consent) |
| 2 | analytics granted; `posthog-js` initialized; `kiln-acceptance` + `identify` | still `notConfigured` |
| 3 | crash reports granted; `StateError('kiln-acceptance test error')` | still `notConfigured` |
| 4 | both categories denied again; `captureEvent` + `reportError` | still `notConfigured` |

`SupportRegistry` is a bootstrap-time snapshot: the module clears its own cached
support on each consent transition. Before 2026-11-22 it never re-recorded, so
reads of `support['analytics']` / `support['crash_report']` kept the pre-consent
`notConfigured` even after events were flowing. The gate was never affected; only
the reported state was stale. Fixed: both modules now re-record support on each
transition (reusing the memoized setup probe), and a module test per suite
asserts the snapshot tracks consent.

## Result

PostHog, project activity over 24 h: **2 events total**.

| Event | Person | Library |
| --- | --- | --- |
| `Identify` | `kiln-acceptance-user` | `posthog-flutter` |
| `kiln-acceptance` | distinct id `01a202b5-…` | `posthog-flutter` |

Absent: `kiln_acceptance_deny` (step 1) and `kiln_acceptance_after_revoke`
(step 4). No `$pageview`. The only PostHog requests on the wire were the
`array.js` load, config, feature-flag polls, and two `/i/v0/e/` posts — all after
the grant in step 2. Nothing was sent during the deny window.

Sentry, project issues: **1 issue**, `FLUTTER-1`
`StateError: Bad state: kiln-acceptance test error`, one event, with
`release=kiln-acceptance`, `environment=production` (the `flavors` extension is
not installed, so no flavor name overrides the default), the `kiln_phase=grant`
context, and `dart 3.13.7` / `flutter 3.47.9` runtime tags. The deny error and
the post-revoke error never reached the envelope endpoint; the only envelope
POST carried the grant-phase error.

Four behaviours are confirmed at the transport boundary, not only in decorators:

- deny: neither SDK is even initialized for sending; calls return `Ok` and drop
  silently (contract-compatible: `capture`/`captureError` return `void`);
- grant: a previously denied session starts sending without rebuilding;
- revoke: `opt_out_capturing` + `reset` (PostHog) and `setUser(null)` + the
  `beforeSend` filter (Sentry) stop later traffic, including a call made after
  revocation;
- no unguarded reporter is reachable: `Analytics` and `CrashReporter` are the
  only registered seams.

## Defects found on the way (not K09 consent behaviour)

**`env:` secret reference did not compile (fixed).** `--answer
api_key=env:KILN_POSTHOG_KEY` rendered
`this.apiKey = String.fromEnvironment('KILN_POSTHOG_KEY')` as a **default
parameter value**, which is not constant, so `flutter analyze` failed with
`non_constant_default_value` in both configs. The fixture patched the two lines
locally to proceed. Fixed at the source: `buildTemplateVars` now emits `const
String.fromEnvironment(...)`; goldens regenerated and a freshly generated app
with `env:` secrets passes `flutter analyze`. Tracked under K24.

**Stale support snapshot after consent (fixed).** See the note under Timeline:
both modules now re-record support on each consent transition.

## What this does and does not prove

- Proves: the real PostHog and Sentry SDKs obey the consent gate end to end over
  real HTTPS, including SDK initialization timing and revocation; the generated
  app compiles and runs with the extensions installed (after the `env:` fix).
- Does not prove: native (Android/iOS) SDK behaviour, `beforeSend` coverage of
  native-initiated events, queued-event draining on process kill, or Sentry
  breadcrumbs — all of which need a device run. The web run used a Chromium
  browser (desktop), not a device.

## Cleanup

The local server, `.dart_tool/k09`, and `.dart_tool/acceptance.env` are removed
after the run. To purge vendor data, delete PostHog events filtered by
`kiln-acceptance*` and resolve/delete Sentry `FLUTTER-1`; both resources are on
free tiers created solely for this acceptance.
