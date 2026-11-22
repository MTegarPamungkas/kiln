# Status

2026-11-21. One page for: what this repository is, what is done, what is left,
and the notes you need before changing anything.

| If you want... | Read |
| --- | --- |
| Where code and docs live | [Repository layout](../folder-structure.md) |
| What is done / left / known caveats | this page |
| Detail per finding, with dates | [Findings](findings.md) (K01–K33) |
| Evidence for an acceptance pass | the dated reports linked under [Done](#done) |

## Done

Everything below is implemented in the working tree and covered by tests in this
repository. "Verified" means it was exercised beyond unit tests (rendered
extension suites, a real local server, or a physical phone); the linked report
has the evidence.

**Core runtime and lifecycle**
- Bootstrap policies: required vs optional capabilities, unavailable hard
  dependencies, bounded support/ready probes. Required modules fail with a typed
  `Failure`; optional ones degrade without blocking unrelated modules.
- Late-initialization fencing: every asynchronous module `ready()` refuses to
  attach listeners or publish after disposal
  ([report](late-init-fencing-2026-11-20.md)).
- Module disposal hooks for owned resources; `Registry.registerOwned`/`dispose`
  cleans up registry-owned services after module disposal, and the support
  registry ignores post-disposal results.

**HTTP stack**
- Real status/Failure semantics, transport option merging, cancellation and
  client ownership in `dio`.
- `HttpRequest.deadline` is a shared per-request budget enforced by retry, Dio
  and REST auth refresh with `network.deadline_exceeded`.
- `http_retry`: serialized generations, cancellable waits, `Retry-After`
  clamping, injectable clock, validated keys, and an optional total time budget
  ([K19](findings.md)).
- `http_cache`: stale-write fencing, refresh deduplication, range/206 bypass,
  eviction by age, and a composed Dio+cache loopback fixture
  ([report](dio-cache-composition-2026-11-20.md)).
- `logger`: URL fragment stripping, bounded recursive redaction, and a per-record
  size cap that also applies when redaction is disabled.

**Auth and sessions**
- Appwrite, REST auth, Supabase and Firebase session machinery: generation and
  commit guards, stale restore/login/fetch rejection, local-first logout,
  backend-scoped token storage.
- Appwrite/Google OAuth fixes (popup cancellation, native redirect arguments)
  verified in earlier live runs.
- Supabase two-user RLS verified on a disposable local stack (owner-only and
  public-read policies, forged owner and anonymous access refused) and browser
  OAuth completed in real Chrome through a local OIDC provider: PKCE S256,
  redirect, code exchange, persisted session, RLS-scoped write
  ([report](supabase-local-rls-2026-11-22.md)).

**Push**
- FCM transport and native Appwrite MQTT transport, with generation fencing.
- Taps verified on a physical Android phone: warm tap, terminated-process
  launch, and signed-out tap/login/return with query preservation.
- Duplicate-tap dedupe, bounded bootstrap when the broker is unreachable, retry
  with backoff, and `PushDeliveryControls` for Android battery/exact-alarm state
  ([report](appwrite-push-routing-2026-11-20.md)).
- Force-stop recovery and offline-then-replayed delivery verified on the phone.

**Live provider acceptance (2026-11-21)**
- The one-command Appwrite coordinator reran from a clean fixture: auth (52
  assertions) and services (52 assertions) on Android and web against the
  self-hosted project. Four coordinator defects were fixed on the way (launcher
  quoting, stale phase reports, reused kernel after a mode switch, cleanup
  false-negative), and all temporary resources were deleted
  ([report](live-provider-coordinator-2026-11-21.md)).

**Data and storage**
- `storage` migrations: per-step recovery checkpoints, crash rollback,
  `MutationLock`; backup export/import validates before mutating.
- `local_db`: journaled backup import with crash recovery, durable sync-queue
  claims with lease takeover, blocking cross-handle/process `MutationLock`;
  real multi-process tests cover lock wait, crash release, a three-process flush
  race, claim expiry, and migration/import crash recovery
  ([report](multiprocess-durability-2026-11-21.md)).
- `secure_storage`: namespaced first-run wipe; `env` typed configuration.
- Supabase signed URLs: a 3-second link expired on the local Storage service, a
  one-hour link kept working, and the extension's own URL resolution produced the
  served path
  ([report](supabase-signed-urls-2026-11-22.md)).

**Media, config, privacy**
- `image_picker`: byte bounds before/while reading, MIME sniffing, and decoded
  dimension limits from the encoded header
  ([report](media-dimension-limits-2026-11-20.md)).
- `remote_config`: latest-wins refresh, strict boolean fallback, probe reuse, a
  TTL-persisted last-known-good snapshot, and a loopback live-endpoint suite
  covering fetch, supersede, HTTP errors, timeout and unreachable degradation
  ([report](remote-config-live-endpoint-2026-11-22.md)).
- Consent gates for analytics/crash reporting, bounded PII redaction.
- Product decisions closed (K16/K17/K27): remote config refreshes on resume
  after `fetchInterval` (opt-out, no native dependency); migration/import
  limits documented; theme/locale gate reports `PersistOutcome` with shared
  copy ([decisions](product-decisions-2026-11-22.md)).
- Live loopback and cross-process acceptance for K21/K22: the registry client's
  timeout and byte budget hold against a real server, and a killed writer's
  half-applied transaction is reversed by the next process without touching user
  files (see [findings](findings.md)).
- Physical-phone acceptance for K26/K29 (no credentials):
  [device report](geolocation-deeplink-device-2026-11-22.md). Geolocation
  returns typed failures when the service is off or permission is denied, flips
  from `ok` to `unavailable` when the service is switched off mid-run (without
  killing the app) and recovers with no restart. Custom-scheme links are
  delivered natively on cold start and while running, and links outside the
  configured path/host boundary are dropped.
- Physical-phone acceptance for K06: a cancelled biometric prompt yields no
  values through `readAll`, and a successful bulk read authenticates once (the
  device counter moved one step for two keys)  ([report](biometric-bulk-read-device-2026-11-22.md)). The not-enrolled path,
  reached on a disposable guest user, exposed a misclassification
  (`unsupportedDevice` despite hardware present); it is fixed and re-verified
  as `permissionDenied` with the read failing closed.
- Physical-phone acceptance for K28: the real `image_picker` plugin returned a
  downscaled JPEG from the system gallery picker (`dims=800x600` read from the
  encoded header), a gallery or camera cancel returned `null` rather than a
  failure, and lost-data recovery returned `null` with nothing pending
  ([report](image-picker-device-2026-11-22.md)). With `max_bytes: 102400`, a
  pushed 6 MB noise PNG was rejected as `media.invalid`/`validation`, so the
  byte bound holds against a real picked file. A camera capture the owner
  approved returned a 162 KB JPEG at the configured `1600x1200`, inside the
  limit; a camera cancel returns `null`.
- Live PostHog and Sentry SDKs obey deny/grant/revoke in a Chromium web run:
  deny sent nothing, grant delivered one `kiln-acceptance` event plus one Sentry
  issue, and revoke stopped later traffic
  ([report](analytics-crash-live-sdk-2026-11-22.md)).
- Native (Android) consent acceptance for K09 against a loopback capture host:
  deny produced no traffic, grant delivered one PostHog batch and one Sentry
  envelope, and neither deny nor post-revoke calls reached the wire
  ([report](k09-native-device-2026-11-22.md)). The same pass found and fixed a
  post-revoke leak: a queued PostHog event was flushed 18 s after revoke, and a
  `/flags/` poll followed the identity reset. `flushAt: 1`, a deferred identity
  rotation and an explicit opt-in per grant now leave **no traffic at all**
  after revoke, re-verified on the phone.
- Live adapter acceptance for K23: the real Appwrite `Functions` and
  `PushTargets` adapters passed 6/6 against the owner's project (deployed
  function invocation with a forwarded body, typed failures for unknown ids and
  bad methods, real push-target create/upsert/update/delete). A skip without
  credentials now reports as a skip, never a pass
  ([report](k23-live-adapters-2026-11-22.md)).
- FCM delivery for K23 on an Android **emulator**: the `appwrite_push` transport
  received real Messaging pushes in foreground and after a swipe-away (process
  restarted from the FCM broadcast, tray notification shown). The pass isolated
  an Appwrite 2.7.2 routing defect — a target with `providerId: null` in a
  project holding more than one push provider is silently not delivered while
  reporting `sent` / `deliveredTotal 1` — and the matching extension gap (no way
  to pass a provider id). Not device evidence; K23's device row stays open
  ([report](fcm-push-emulator-2026-11-23.md)).

**CLI, installer and tooling**
- Transactions with journal/rollback, project-wide `ProjectLock` for every
  mutating command, bounded registry/archive/verifier work, atomic metadata
  writes.
- Manifest ↔ module metadata parity checks, bundle/registry/catalog generators,
  golden render snapshots, rendered per-extension analysis and tests, a composed
  27-module fixture with randomized bootstrap-order checks
  ([report](composed-fixture-2026-11-21.md)), and the
  manual fixtures under `tool/e2e/`.

## Not done

None of these is a surprise defect: they are either external acceptance, a
policy decision, or a known cost that was deliberately deferred.

| Area | What is missing | Needs |
| --- | --- | --- |
| K06 biometric | Biometric lockout path (temporary/permanent) | Deliberately causing a lockout |
| K07 secure storage | Real Keychain reinstall with custom service/access-group | iOS device |
| K08/K28 push taps, media | iOS tap/terminated launch; HEIC and iOS picker | iPhone |
| K09 analytics/crash | iOS native path | iPhone |
| K23 real adapters | FCM delivery on a physical device (`dev.tegar.appwrite_demo`) — emulator delivery now passes; device MQTT broker; provider-id option for the push module | Android device |
| K25 provider exchange | Real Google/Apple token exchange into the backend | Provider credentials |
| K26 geolocation | iOS permission/service races | iOS device |
| K29 deep links | Native delivery of custom-scheme links on iOS | iPhone |
| K05 Neon | Retired at the owner's request | Nothing |

Detail and per-finding evidence: [findings](findings.md). The 33-row status
summary lives at the end of this page.

## Special notes

**Owner rules for this repository**
- Chat and progress notes: Indonesian. Code, docs, CLI output and commits:
  English.
- Do not commit, publish or deploy unless the owner asks. The tree carries a
  large uncommitted change set; preserve it.
- Never write API keys, passwords, cookies or tokens into source, docs, logs or
  journals. Credentials stay in memory or an ignored temp file that is deleted.
- After a native change, uninstall the test app before installing again.

**Environment and fixtures**
- Self-hosted Appwrite: `https://appwrite.tegardev.id/v1`, project
  `6afebe9d000e9c351b3e`; native push broker `mqtts://push.tegardev.id:8883`
  (DNS-only, not proxied; do not put MQTT behind the orange-cloud proxy).
- Test phone: `c7d2692b` (M2007J20CG, Android 13). Emulator runs are not device
  evidence.
- Manual fixtures live under `.dart_tool/` and are started by hand:
  `tool/e2e/push_routing_host.mjs`, `tool/e2e/dio_cache_probe.dart`,
  `tool/appwrite_platform_probe.dart`. They are not part of `flutter test`.
- Temporary Appwrite resources owned by a run are listed in
  `.dart_tool/*_ownership.json`. Delete only those, never the real Google user.

**Known limits to keep in mind**
- `Future.timeout` cannot cancel the underlying plugin or network call; the
  fences stop late results from mutating state, not the work itself.
- The file lock is advisory (POSIX locks are per process, so two isolates in one
  process are not excluded); nesting the same lock path in one Windows process
  waits for itself. One isolate per browser origin on web.
- Sembast documents single-process access. The multi-process flush race uses a
  shared durable store; the crash tests open Sembast only after the killed
  process is gone.
- Extensions that share a capability (auth backends, push transports, state) or
  render the same files (bloc/riverpod notes feature) cannot be installed
  together. The composed fixture checks one reviewed compatible set; each
  alternative is checked on its own.
- `Future.timeout` fences late results; it cannot cancel a plugin call. SDK-backed
  token providers accept the request deadline but can only honour it where the
  SDK exposes cancellation (REST auth does).
- `Registry.dispose` only disposes services registered with `registerOwned`;
  plain singletons and module-owned resources stay with their owners.
- Doze deferral was never observed on the test phone; long idle and reboot
  delivery are unverified.
- iOS push and Apple OAuth remain unverified.
- `Storage`/SharedPreferences is not encrypted; do not put secrets there.
- An image header can lie about its size; the decoder catches it, the validator
  only bounds what the header claims.
- Backup recovery restores exactly what the journal lists; it cannot detect an
  unrelated writer inside an interrupted import.

**Commands that must stay green**

```bash
dart analyze
dart run test                       # in packages/kiln_core and packages/kiln_cli
dart run tool/check_metadata.dart
dart run tool/check_versions.dart
dart run tool/check_docs.dart
dart run tool/verify_extensions.dart --only <id> --analyze --test
dart run tool/verify_composed.dart --analyze --test
dart run tool/bundle.dart           # after changing a brick or manifest
dart run tool/registry.dart
dart run tool/gen_catalog_docs.dart
```

## Status summary (K01–K33)

`Fixed` = implemented and tested locally; `Partial` = the named remainder is
open; see [findings](findings.md) for each entry.

| ID | State | One line |
| --- | --- | --- |
| K01 | Fixed | Real HTTP responses reach policy middleware; composed loopback tests. |
| K02 | Fixed | Cancellation and timeouts reach the transport; a server mutation is still irreversible. |
| K03 | Fixed | Session cannot be repopulated after logout; backend-scoped tokens. |
| K04 | Fixed | Stale-result guards, two-user RLS on a local stack, and browser OAuth through a local OIDC provider. |
| K05 | Retired | Neon removed at the owner's request. |
| K06 | Fixed | Bulk reads authenticate once; cancelled and not-enrolled reads fail closed on device; not-enrolled misclassification fixed. |
| K07 | Fixed | First-run wipe respects the storage namespace; real Keychain reinstall open. |
| K08 | Fixed | Launch tap reaches the router (verified on device); iOS tapping open. |
| K09 | Fixed | Live traffic obeys deny/grant/revoke on web and Android; post-revoke queue leak fixed (`flushAt: 1`, deferred reset, opt-in per grant); iOS native open. |
| K10 | Fixed | Registry-owned services dispose once in reverse order; bootstrap wires it to shutdown. |
| K11 | Fixed | Firebase rejects unsupported URL expiry; Supabase signed-URL lifetime verified on a local stack. |
| K12 | Fixed | Manifest/AST parity for every extension plus a composed 27-module fixture with randomized order resolution. |
| K13 | Fixed | Typed required-module failures, optional degradation, dependent readiness; plugin cancellation stays fencing by design. |
| K14 | Fixed | Riverpod controller handles stream errors, empty completion and disposal. |
| K15 | Fixed | Codegen prompt removed; both generators install together. |
| K16 | Fixed | Latest-wins refresh, strict booleans, persisted last-known-good with TTL, live loopback endpoint suite; resume refresh gated by `fetchInterval` (opt-out). |
| K17 | Fixed | Migrations/import verified across real processes; large-store cost and unrelated-writer detection are documented limits. |
| K18 | Fixed | Blocking cross-process lock, durable claims; real three-process race, crash-release and lease tests. |
| K19 | Fixed | Per-request deadline shared by retry, Dio and REST refresh; typed deadline failure. |
| K20 | Fixed | URL fragments stripped, redaction bounded, and every record capped even without redaction. |
| K21 | Fixed | Archive/registry/verifier bounds tested live: loopback timeout and oversize cut-off; retry UX optional. |
| K22 | Fixed | All mutating CLI commands locked; cross-process crash recovery reverses a half-applied transaction; direct callers own the lock. |
| K23 | Partial | Real Appwrite `Functions` and `PushTargets` adapters verified live (6/6); FCM delivery verified on an emulator (foreground + swipe-away), with the multi-provider routing defect recorded; physical-device delivery open. |
| K24 | Fixed | Secrets reference env values; existing installs need a one-time migration. `env:` now renders `const`, so generated configs compile. |
| K25 | Partial | Credential fields separated; real provider exchange open. |
| K26 | Fixed | Geolocation errors normalized; device service race verified on a phone, iOS open. |
| K27 | Fixed | Theme/locale writes serialized; gate reports `PersistOutcome` and shared ARB copy covers a session-only save. |
| K28 | Partial | Byte/dimension limits, shared recovery policy, and real-plugin gallery/oversize/cancel/camera acceptance on Android; HEIC and iOS open. |
| K29 | Fixed | Custom-scheme links obey path/host policy; Android native delivery verified, iOS open. |
| K30 | Fixed | Stale refresh cannot overwrite an invalidated entry. |
| K31 | Fixed | Range/206 never occupies the full-response cache key. |
| K32 | Fixed | Add/remove verification is inside the commit boundary. |
| K33 | Fixed | CLI cancellation output is English. |

## Continuation order

1. External acceptance, one at a time with the owner: K25 live provider
   checks, K09 native SDK traffic, K06/K07/K28 devices, iOS OAuth/push,
   iOS geolocation and deep-link delivery.
2. K17 revisited only if a real app hits multi-tens-of-MB stores mid-migration
   (incremental checkpoints become a new finding then).
3. Repeat the push/media/device procedures after any native change; keep the
   uninstall/install rule.

Process notes that duplicated this page were removed on 2026-11-21; the
directory now holds this status page, [findings](findings.md), and one dated
evidence report per pass.
