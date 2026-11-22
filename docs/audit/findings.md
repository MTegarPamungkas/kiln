# Review findings

Current completion checklist: [all K01-K33 statuses and next steps](current-status.md).
That page is the single status entry point and supersedes completion claims in
the dated implementation history below.

The audit directory keeps only this findings file, the status board, and one
dated evidence report per acceptance pass:
[push routing](appwrite-push-routing-2026-11-20.md),
[Appwrite services and push](appwrite-services-push-2026-11-20.md),
[Android/web auth](android-web-auth-2026-11-19.md),
[late-init fencing](late-init-fencing-2026-11-20.md),
[cross-handle durability](cross-handle-durability-2026-11-20.md),
[media dimension limits](media-dimension-limits-2026-11-20.md),
[Dio + cache composition](dio-cache-composition-2026-11-20.md),
[Supabase local RLS and browser OAuth](supabase-local-rls-2026-11-22.md),
[Supabase signed-URL lifetimes](supabase-signed-urls-2026-11-22.md) and
[remote config live endpoint](remote-config-live-endpoint-2026-11-22.md). Process
notes that duplicated this file or the status board were removed on 2026-11-21.

Date: 2026-11-19. Paths below use
`E/<id>/<file>` as shorthand for
`extensions/<id>/brick/__brick__/lib/extensions/<id>/<file>`.

Status vocabulary:

- **Observed**: the implementation pattern is present in inspected source;
  its suggested regression has not been executed in this analysis pass.
- **Risk**: a missing guard or boundary permits a plausible failure; reproduce
  it before selecting the final implementation or asserting actual harm.
- **Decision**: the contract/product behavior needs an explicit policy.
- **External**: source analysis cannot establish provider/device behavior.

P1 means session/privacy/data correctness; P2 means reliability, integration,
and setup; P3 means optional polish. No P0 incident is asserted by this review.

## K01 - HTTP error responses never reach response-based middleware

**P1 - Observed - dio, rest_auth, http_retry.**
`DioClient._send` accepts only 2xx/304 and maps a rejected Dio response to a
Failure. `UnauthorizedHandler.handle` instead awaits a response and checks
`response.statusCode == 401`; it does not handle that Failure. REST auth also
contains response-based credential and refresh mapping. A real 401 therefore
can bypass the intended refresh/retry/clear path even when fake-client tests
pass. Retry-After response handling can similarly be bypassed for 429/503.

**Fix:** define one HTTP status contract across transport and middleware.
Prefer returning received HTTP responses and mapping failures at the policy
boundary, or deliberately teach every consumer the chosen Failure shape.
Preserve distinction between transport failure and an HTTP rejection.
**Accept:** a local server returns 401, refresh succeeds, and exactly one retry
uses the new token; failed refresh clears the intended session; 429 Retry-After
and credential 401 mapping work through the actual DioClient/pipeline.

**Implementation 2026-11-19:** `DioClient` now returns every received HTTP
status and maps only transport failures to `Failure`, so auth, retry, cache, and
log middleware apply their own policies to real responses. Evidence: dio client
tests (401 returned, 429 Retry-After preserved, transport failure mapped), a new
local `HttpServer` test (401, 429, timeout, cancellation), and the rest_auth
pipeline/credential tests. Remaining: the full
dio+rest_auth+http_retry+http_cache+logger local-server fixture is still
unbuilt (the dio+http_cache pair is now covered by
`tool/e2e/dio_cache_probe.dart`), so "exactly one refresh retry through the real
transport" stays unverified; multipart/download helpers continue to reject
non-2xx directly.

## K02 - Cancellation and timeout settings do not reach Dio fetch

**P2 - Observed/Risk - dio, kiln_core.**
`DioClient._send` checks the cooperative cancel flag only before `_dio.fetch`.
It does not pass a Dio CancelToken or check cancellation after awaiting the
response. It constructs a new RequestOptions without copying configured
connect/receive timeout values from BaseOptions. `HttpCancelToken` exposes no
cancellation subscription. Verify the resolved Dio API behavior before changing
the timeout implementation; the adapter currently supplies no timeout fields.

**Fix:** merge request options with transport defaults, add a cancellation
notification seam if aborting in-flight work is promised, and close owned Dio
resources. Clarify that cancellation cannot undo a server mutation.
**Accept:** cancel after a slow request starts; the caller receives cancelled
and resources terminate. A slow server respects configured request bounds;
injected Dio configuration and multipart/download helpers stay consistent.

**Implementation 2026-11-19:** `HttpCancelToken.onCancel` provides the
notification seam; `DioClient` passes a Dio `CancelToken`, checks cancellation
after the await, and builds request options through `Options.compose` so
BaseOptions connect/receive timeouts reach the fetch. Evidence: adapter tests
assert configured timeout values and in-flight abort; the local-server test
asserts receive timeout and cancellation. `DioModule.dispose` closes the client
it created (see K10); cancellation still cannot undo a server mutation
(documented).

## K03 - REST auth can repopulate a session after logout

**P1 - Observed - rest_auth.**
`RestAuth.signIn/signUp/reloadSession/_apply` have no operation generation or
serialized session commit. `_apply` saves tokens/user and emits after awaits.
TokenRefresher protects its own late token writes, but that does not protect
these paths. An old refresh rejection also calls `clearSession` from
`_exchangeRefresh`, without checking whether a newer login replaced it.
Sign-out waits for remote work before clearing local state.

**Fix:** make all session-changing paths share a revision/commit boundary,
clear locally before remote logout, scope stored state to backend/app identity,
and reject late error side effects as well as late success results.
**Accept:** delayed login/me/refresh success and failure after logout or a
different login cannot write credentials, clear the new user, or emit old state.
Storage failures and offline logout need explicit observable outcomes.

**Implementation 2026-11-19:** `RestAuth` uses a generation counter plus a
serialized commit queue; sign-in/sign-up/reload results that lose to a newer
operation throw `auth.cancelled` without writing or emitting; `signOut` clears
local state before the remote logout and sends the captured token; a refresh
401/403 clears only when the generation and stored refresh token still match;
token storage carries a backend identity and discards tokens from another
backend or legacy unmarked data. Evidence: delayed login vs logout/login,
delayed reload vs login, stale refresh rejection, local-first logout, storage
failure, and backend-scope tests. Remaining: legacy installs sign in once after
the scoped-key migration.

## K04 - Supabase adapter auth lifecycle lacks stale-result guards

**P1 - Observed/Risk - supabase.**
`restore/signIn/signUp` apply awaited sessions without a revision check.
`signOut` clears adapter state only after the gateway succeeds. `_start` can
subscribe again after dispose because there is no disposed guard. The social
browser path accepts an already-existing `currentSession` immediately after
launching OAuth, so a prior session may be reported as the new flow's result.

**Fix:** coordinate SDK events and adapter operations, specify offline logout,
guard disposal, and match OAuth completion to the requested flow. Do not remove
valid SDK refresh behavior while adding application-level guards.
**Accept:** delayed restore/login cannot win after logout; a failed remote
logout follows the documented local policy; an existing user does not complete
another OAuth attempt prematurely. Add a local-stack two-user/RLS test.

**Implementation 2026-11-19:** The adapter uses a generation counter plus a
serialized commit queue; delayed `restore`/`signIn`/`signUp` results throw
`auth.cancelled` instead of overwriting a newer session. `signOut` clears local
state first, ignores remote failures, and blocks delayed SDK events from
resurrecting the user; the SDK gateway falls back to a local-scope sign-out when
the remote call fails. `_start` and stream writes are disposed-guarded. The
browser OAuth flow waits for a session produced after launch, so a prior session
cannot satisfy the request, and a `SupabaseCredentialSource` forwards the raw
nonce/code. Evidence: delayed restore/login vs sign-out, offline sign-out, prior
vs new OAuth session, and credential-source tests plus the rendered suite.

**Implementation 2026-11-22:** Both acceptance items landed against a disposable
local Supabase stack. `notes`/`public_notes` policies were exercised by two real
GoTrue users through PostgREST: owner-only read/write, cross-user select/update/
delete refused, a forged `user_id` rejected by `WITH CHECK`, and anonymous reads
and writes refused. That matrix runs as an opt-in rendered test
(`supabase_local_rls_test.dart`, skipped unless `KILN_SUPABASE_LOCAL_RLS=1`) and
as `tool/e2e/supabase_local_rls_probe.dart` (16 checks). Browser OAuth ran in a
real Chrome against the stack with a local OIDC provider registered as GoTrue's
`keycloak` provider: PKCE S256 challenge, redirect through GoTrue, code exchange,
persisted session, and an RLS-scoped insert owned by the OAuth user (15 checks,
`tool/e2e/run_supabase_oauth.mjs`). A real Google/Apple exchange still needs
provider credentials and stays under K25. Evidence:
[report](supabase-local-rls-2026-11-22.md).

## K05 - Retired: Neon removed

The owner requested removal of the Neon extension on 2026-11-19. Its source,
workspace entry, bundle, archive, and active documentation were removed. This
finding is historical and is no longer an implementation task.

## K06 - Biometric bulk reads bypass authentication

**P1 - Observed - biometric.**
`BiometricProtectedStorage.read` authenticates, but `readAll` delegates directly
to the underlying SecureStorage. A caller can obtain the same protected values
with no biometric check. Existing focused tests cover read/write, not bulk read.

**Fix:** use the same authentication policy for every value-returning read,
or explicitly forbid bulk reads on this wrapper. Decide separately whether
delete/clear/write require confirmation; do not accidentally change that policy.
**Accept:** denied/cancelled biometric authentication yields no values through
readAll, and successful bulk read authenticates once rather than once per key.

**Implementation 2026-11-19:** `BiometricProtectedStorage.readAll` authenticates
once before delegating; a denied challenge returns no values. Write, delete, and
clear keep their existing unauthenticated policy. Evidence: grant and deny tests
for `read` and `readAll`, plus the rendered extension suite. Remaining: live
device tests for missing enrollment and a biometric prompt cancelled by the OS.

**Device evidence 2026-11-22:** on the physical phone (`c7d2692b`, Android 13,
one fingerprint enrolled) a `readAll` cancelled with BACK returned
`Failure(cancelled, cancelled)` and no values, and a `readAll` after a real scan
returned both seeded values while the device fingerprint `accept` counter moved
23 → 24 — one prompt for two keys. See
[device acceptance](biometric-bulk-read-device-2026-11-22.md). Remaining: the
not-enrolled path, which needs the owner's fingerprints removed (destructive
personal change, not performed).

**Defect 2026-11-22 (not-enrolled path):** the not-enrolled path was reached
without touching the owner's enrollment by creating a disposable Android guest
user (no fingerprints, no screen lock) and installing the probe into it. The
probe reported `unsupportedDevice` — "This device has no biometric hardware" —
although the phone has a fingerprint sensor. Cause: `Biometric.availability()`
took `isDeviceSupported()` as the hardware signal. On Android that maps to
`isDeviceSecure || canAuthenticateWithBiometrics()`, so it is `false` for a user
profile with no screen-lock credential, and `true` for a device with only a
PIN even when nothing is enrolled. `canCheckBiometrics()` is the real hardware
probe (`deviceCanSupportBiometrics`), which stays `true` with hardware present
and nothing enrolled. The wrong signal also made a lock-screen-only device look
biometric-capable at bootstrap.

**Fix 2026-11-22:** `availability()` now probes `canCheckBiometrics()` for
hardware and only falls back to `isDeviceSupported()` when that probe is false,
and it never calls `availableBiometrics()` without hardware. A user with
hardware and no enrollment now resolves to `notEnrolled` →
`SupportState.permissionDenied`, and only a false hardware probe resolves to
`noHardware` → `unsupportedDevice`. Regression tests cover both branches, and
the existing app-lock "no biometrics" fixture now clears the hardware probe too
instead of only `supported`. Evidence: the guest-user run above plus the
rendered biometric suite. Re-verified on the guest user with the corrected
build: support `permissionDenied` ("Biometrics are not enrolled on this
device.") and `readAll` failing closed with `Failure(permission.denied,
permission)`.

## K07 - iOS first-run wipe ignores the secure-storage namespace

**P1 - Observed - secure_storage.**
`FirstRunWipe.run` enumerates a raw gateway's readAll and deletes every key.
Regular `KeystoreSecureStorage.clear` correctly filters `config.prefix`.
The module constructs a second default gateway for wiping instead of reusing
the configured one. It reads optional Storage but does not declare the runtime
optional dependency, making marker availability depend on module ordering.

**Fix:** limit cleanup to owned keys and the configured service/access options,
declare runtime ordering, and define explicit opt-in/migration behavior for any
intended whole-store deletion. Persist the marker only after successful cleanup.
**Accept:** an unrelated sentinel key survives; owned keys are removed once;
custom options and marker/delete failures are tested; shuffled module order
still produces the same first-run behavior.

**Implementation 2026-11-19:** `FirstRunWipe` now deletes only keys that start
with the configured prefix, uses the registered config/platform options in the
module, and writes the marker only after cleanup succeeds. The module declares
its optional `storage` dependency so the marker availability is ordered. Evidence:
sentinel-key, delete-failure, non-iOS, and marker tests plus a module
`optionalRequires` test; the rendered extension suite passes. Remaining: live
Keychain verification with custom service/access-group options on an iOS device.

## K08 - Notification cold-launch payload can be lost before routing

**P1 - Observed - notifications, go_router.**
Notification initialization calls `NotificationTapHub.start`, which broadcasts
the launch payload immediately and marks it emitted. GoRouterModule optionally
depends on notifications, so its router starts listening later in bootstrap.
The broadcast hub has no pending replay for a future first listener.

**Fix:** retain launch/tap state until a consumer can receive it, with a defined
one-time replay/acknowledgement policy. Include taps arriving during initialization.
**Accept:** initialize notifications first, subscribe later, and receive the
launch route exactly once. Re-listening and warm/background taps do not duplicate
navigation. Verify a real cold-start notification after local regressions pass.

**Implementation 2026-11-19:** `NotificationTapHub` retains the launch payload
and any tap that arrives before the first listener, then replays them once when
a consumer subscribes; re-listening receives only live taps and a second tap is
not replayed. Evidence: hub replay tests, a `DeviceNotifications` late-subscriber
test, and the rendered notifications suite. `AppRouter` already guards duplicate
navigation by comparing the current location. Remaining: verify a real
cold-start notification on Android/iOS after local regressions.

## K09 - Telemetry SDK initialization sits outside the consent wrappers

**P1 - Observed boundary gap; outbound behavior unverified - analytics, crash_report.**
Module support/ready initializes PostHog/Sentry whenever config/flavor is active,
independently of consent. Decorators gate explicit API calls, not SDK init,
automatic capture, SDK queues, or global integrations. Sentry init supplies no
consent-aware beforeSend boundary. Raw gateways/concrete reporters are also
registered, bypassing the safe contract decorators. Consent revocation does not
coordinate SDK shutdown/queued state. This is not proof that an event was sent.

**Fix:** define the privacy guarantee at the SDK transport boundary; initialize
on consent or configure a verified hard opt-out/filter and revoke queued data
and identity. Avoid globally available unguarded reporters unless intentional.
**Accept:** instrument actual SDK outgoing traffic under deny/grant/revoke;
automatic errors, queued events, identify/reset, breadcrumbs, and concurrent
revocation obey the chosen policy. Do not rely only on decorator fake tests.

**Implementation 2026-11-19:** Both modules initialize their SDK only after the
matching consent category is granted; a grant starts or re-enables the SDK
(analytics also re-identifies the current session) and a revocation opts out and
resets the analytics identity or clears the Sentry user. A transport-level
consent filter (`PostHogConfig.beforeSend`, Sentry `options.beforeSend`) drops
events if consent disappears, and support reports "waiting for consent" instead
of initializing. The raw gateway and concrete reporter are no longer registered
services, so application code cannot bypass the decorators. Evidence: module
tests for wait/grant/revoke/retry, support waiting-state tests, gateway fakes
recording the consent callback, and the rendered suites. Remaining: instrument
actual SDK outgoing traffic (queued events, automatic errors, breadcrumbs) on a
device under deny/grant/revoke. PostHog's `beforeSend` does not cover every
native-initiated event, so its opt-out remains the hard boundary.

**Live acceptance 2026-11-22:** a generated app (`analytics` + `crash_report`)
ran as a web build in a Chromium browser against real PostHog (project `758963`)
and Sentry (project `flutter`) resources. Deny sent nothing and no SDK
initialized for sending;
grant produced exactly one `kiln-acceptance` event plus one `Identify` and one
`FLUTTER-1` `StateError`, all tagged `kiln-acceptance`; revoke stopped further
traffic including a call made after revocation. Evidence:
[analytics-crash-live-sdk-2026-11-22.md](analytics-crash-live-sdk-2026-11-22.md).
Remaining: native (Android/iOS) SDK behaviour and `beforeSend` coverage of
native-initiated events, which need a device run. Follow-up from that pass: after
a consent grant, `SupportRegistry` reported the pre-consent `notConfigured`
because the module cleared but never re-recorded support. Fixed 2026-11-22: both
modules now re-record support after each consent transition (grant and revoke),
reusing the memoized setup probe so SDK setup is not repeated; a module test in
each suite asserts the snapshot follows consent.

**Native device acceptance 2026-11-22:** on the physical phone, with both
extensions pointed at a loopback capture host (`adb reverse`), deny produced
**zero** requests, grant initialised both SDKs and delivered one PostHog
`/batch` (`$identify` + `kiln_native_grant`) and one Sentry envelope (error,
breadcrumb, `kiln_phase=grant` context, `release=kiln-native-acceptance`), and
the deny/post-revoke calls never appeared on the wire
([k09-native-device-2026-11-22.md](k09-native-device-2026-11-22.md)).

**Defect found on device (fixed 2026-11-22):** a queued event leaked after
revoke. With a 10 s grant window (shorter than the 30 s flush timer),
`kiln_native_grant` was delivered at `+18 s` after `revoke_start`: the event
passed `beforeSend` at capture time, and `optOut()` stopped new captures but did
not discard the pending queue, so the periodic flush sent it post-revoke. A
`/flags/` poll also went out, because revoke called `reset()`, which rotates the
identity and reloads flags. A third cause was found while fixing: `optOut()`
persists across launches, so a session that granted consent after an earlier
revoke stayed silent.

Fix: `flushAt = 1` (`AnalyticsConfig.pendingEventLimit`) keeps at most one event
queued; the identity rotation is deferred to the next grant (`_resetOnNextGrant`)
so revoke makes no network call; and every grant calls `setEnabled(true)` so a
persisted opt-out cannot outlive the consent that replaced it. Re-verified on the
phone: during a 10 s grant window the only traffic was the config fetch, two
PostHog batches and one Sentry envelope, all before `revoke_start`; after revoke
**nothing** was sent and no deny/post-revoke event appeared. Residual: the
deferred reset means the old anonymous id stays on disk until the next grant,
while nothing is transmitted.

Sentry was correct in every run: no periodic flush, and its gate runs at send.

## K10 - Several modules do not dispose the resources they create

**P2 - Observed - deep_link, local_db, theme, l10n, dio; analytics follow-up.**
DeepLinkModule never forwards disposal to DeviceDeepLinks, although it owns a
plugin stream/controller. LocalDbModule never closes its SembastLocalDatabase.
ThemeModule never disposes ThemeModeController. L10nModule likewise does not
dispose its LocaleController. DioModule has no transport close path.
GetItRegistry does not automatically register disposal callbacks. Analytics
disposes its session listener but does not await queued identity work or provide
an SDK shutdown path. Sembast's rejected `_opening` future is cached indefinitely.

**Fix:** record ownership at construction; dispose owned resources once,
guard pending work against disposal, and permit retry after a failed DB open.
**Accept:** bootstrap/dispose repeated twice leaves no active listener/socket/DB
handle; late work cannot use disposed notifiers; injected resources follow an
explicit ownership policy. A transient initial DB-open failure can recover.

**Implementation 2026-11-19:** `DeepLinkModule` disposes the device link
subscription/stream, `LocalDbModule` closes its Sembast handle, and `ThemeModule`
/ `L10nModule` dispose their controllers. A rejected Sembast open is no longer
cached, so the next call retries. `ThemeModeController` and `LocaleController`
ignore late load/set results after disposal. `DioClient.close` closes only a
transport it created; the module closes its own on shutdown, and analytics
shutdown now awaits queued identity work and flushes its SDK. Evidence:
idempotent module-dispose tests, delayed theme load, disposed controller
updates, DB open retry/close, and Dio ownership tests plus the rendered suites.
Remaining: real device verification of listener/handle release, and the generic
`GetItRegistry` disposal callback is still not automatic.

**Implementation 2026-11-20:** audited every module with an asynchronous
`ready()` for work that resumes after bootstrap disposal. `DeviceNetworkMonitor`,
`FirebaseSessionBridge`, the FCM `AppwritePushTransport`, `RestSessionBridge`,
`SocialSignOutListener`, `SupabaseLinkHandler`, `SupabaseSessionBridge`,
`RemoteConfigModule.ready` and `DeviceNotifications.initialize` now check
disposal between awaits and refuse to attach listeners or publish afterwards;
rest_auth, social_login and supabase hand their components to the lifecycle for
disposal. Regressions drive the race with gated platform calls. See
[late-init fencing](late-init-fencing-2026-11-20.md). Remaining:
`BiometricAppLock.initialize` is lazy and unfenced, and plugin calls can only be
fenced, not cancelled.

**Implementation 2026-11-21:** `Registry.registerOwned` makes ownership explicit:
the registry runs the supplied callback (or an inferred `Disposable.dispose`)
once, in reverse order, and `Registry.dispose` then clears every registration.
`KilnBootstrap` registers `registry.dispose` with the lifecycle, so it runs after
module disposal. A failing callback does not skip the others. Evidence:
reverse-order/idempotent/error-isolation registry tests and a bootstrap test that
disposes an owned service. Plain `registerSingleton` stays manual, so a module's
own resource is never double-disposed. See
[contract decisions](contract-decisions-2026-11-21.md).

## K11 - Firebase silently ignores URL expiry requests

**P1 - Observed/Decision - firebase, FileStorage contract.**
FirebaseFileStorage.url documents that it ignores expiresIn and returns the
regular download URL. Appwrite was changed to fail explicitly for this case,
while Supabase issues signed URLs. A backend swap therefore changes the
caller-requested lifetime without an error.

**Fix:** specify FileStorage expiry/capability semantics. Reject unsupported
expiry consistently or use a trusted signing backend; keep privileged signing
credentials out of the app. Document public URL versus session URL behavior.
**Accept:** every backend's expiry tests either validate a supported lifetime
or receive a typed unsupported failure; none silently returns a permanent link
when the caller explicitly requested expiry.

**Implementation 2026-11-19:** `FirebaseFileStorage.url` now rejects a non-null
`expiresIn` with `validation.unsupported_value`/unsupported kind instead of
returning the permanent download URL; the `FileStorage.url` contract documents
that `expiresIn` is a requested capability and that unsupported implementations
must fail rather than silently ignore it. Appwrite keeps its explicit rejection;
Supabase issues signed links with the requested lifetime. Evidence:
Firebase rejection test, existing Appwrite/Supabase URL tests, and the
rendered suites.

**Implementation 2026-11-22:** the Supabase lifetime is now verified against a
real Storage service on the local stack. A 3-second link served the object and
was rejected after expiry; a one-hour link kept serving it; an anonymous key
could not sign without a policy. The rendered test also passes the relative link
through the extension's `resolveSupabaseSignedUrl`, so the served path comes from
production code. Firebase stays a local rejection by policy and needs no provider
round trip. Evidence:
[report](supabase-signed-urls-2026-11-22.md).

## K12 - Manifest capabilities and runtime module metadata drift

**P1 - Observed - firebase, rest_auth, secure_storage; wider parity review.**
Firebase's manifest provides account_management/token_provider but the module
provides set omits both despite registering their contracts. RestAuthModule
provides only auth while its manifest also lists those capabilities.
SecureStorageModule omits runtime optionalRequires(storage). LocalDbModule
omits its manifest's optional secure-storage edge; its lazy opener reduces but
does not eliminate early-access ordering risk. Other optional edges differ too.

**Fix:** compare parsed manifests with instantiated rendered modules, including
provides/requires/optionalRequires/platforms. Use a canonical definition where
possible. A text regex alone is insufficient: generic-free Dart set literals
and quoted YAML strings caused false positives during the exploratory scan.
**Accept:** randomized module order resolves required token/account/storage
providers, and a 35-extension parity test catches deliberate metadata drift.

**Implementation 2026-11-19:** Added `tool/check_metadata.dart` and
`test/metadata_parity_test.dart`, which parse every manifest and its rendered
`KilnModule` and compare `id`, `provides`, `requires`, `optionalRequires`, and
`platforms`. Fixed the actual drift: Firebase now provides
`token_provider`/`account_management` and mirrors its platform list; REST auth
provides those capabilities; Local DB declares optional secure storage; Appwrite
push and social login mirror their platform lists; biometric, bloc, flavors,
riverpod, and connectivity manifests declare the optional edges their modules
already use. Remaining: the randomized-order resolution check is covered at the
graph level by existing bootstrap tests but not yet with all 35 rendered modules
in one app.

**Implementation 2026-11-21:** `tool/verify_composed.dart` renders the maximal
compatible set into one app. All 34 extensions cannot boot together: four provide
`auth`, two provide `push_transport`, two provide a state capability, and
`ModuleGraph` rejects duplicate providers; mutually exclusive alternatives also
render the same `lib/features/notes/...` files. The fixture therefore renders one
reviewed representative per capability (27 modules), generates
`extensions.g.dart` from that set, and runs a generated suite that checks the
selected ids, unique capability providers, 25 randomized input orders with every
required provider before its consumer, and registration in a resolved random
order exposing `TokenProvider`, `AccountManagement`, `AuthRepository`, `Storage`,
`LocalDatabase`, `RemoteDatabase`, `FileStorage`, `HttpClient`, and `AppLogger`.
`flutter analyze` covers the composed application. Evidence:
[composition and log bounds](composed-fixture-2026-11-21.md). Remaining:
alternative backends/state/notification extensions are verified one at a time by
`verify_extensions` and the parity check, because they cannot coexist in one
bootstrap by design.

## K13 - Bootstrap needs explicit unavailable-dependency and timeout policy

**P2 - Decision/Risk - kiln_core, env, every module.**
Bootstrap registers then probes a module. If support is unavailable/notConfigured,
ready is skipped but the registered services remain; graph resolution already
considered that module a provider. Env validation in ready is consequently skipped
when support reports invalid config. Future.timeout stops waiting but does not
cancel a support/ready operation; late initialization can outlive cleanup.

**Fix:** define required versus optional startup failure, dependent readiness,
and late-operation cancellation/commit rules. Keep optional platform features
usable without making an invalid required backend look ready.
**Accept:** a required invalid Env/backend fails or degrades in the documented
way; optional unsupported modules do not break unrelated modules; a late ready
completion after timeout cannot reopen resources or mutate disposed services.

**Implementation 2026-11-20:** the late-completion rule is now enforced per
module rather than left to convention: every module with asynchronous `ready()`
was audited, eleven owners gained disposal checks or lifecycle-owned disposal,
and the audited modules can no longer attach listeners or publish into closed
streams after cleanup. The policy itself is unchanged (`Future.timeout` still
cannot cancel a plugin call). See
[late-init fencing](late-init-fencing-2026-11-20.md).

**Implementation 2026-11-21:** the policy is now typed and tested rather than
convention. A required module whose support is unavailable stops bootstrap with
the `Failure` derived from its support state (`configuration.missing` for
`notConfigured`, `unavailable`, or the matching `support.*` code); missing
required capabilities throw a typed `unavailable` failure with the missing list.
Optional modules keep their registrations, lose their capability, and skip
`ready`; dependents that require the missing capability skip `ready` too.
`Future.timeout` still only fences a plugin call, which is documented as the
final cancellation boundary. Evidence: typed required/notConfigured bootstrap
tests, dependent-readiness and unrelated-module tests, and the existing fencing
suite. See [contract decisions](contract-decisions-2026-11-21.md).

## K14 - Generated Riverpod controller ignores stream errors/completion

**P1 - Observed - riverpod.**
NotesController.build listens with only an onData callback. If watchNotes errors
before the first value, the first Completer remains unresolved and the error is
unhandled. Later errors also bypass AsyncError. An empty completed stream leaves
initial loading unresolved. Mutation completions have no disposal-generation guard.

**Fix:** handle initial/later stream errors, empty completion, cancellation and
provider rebuild/disposal. Preserve one subscription as the source of data.
**Accept:** a stream that errors or completes before its first value produces
the documented UI state; later errors remain observable; dispose during a
mutation cannot write through an invalid ref/controller.

**Implementation 2026-11-19:** `NotesController.build` handles initial errors,
later errors, and an empty completion before the first value; both paths produce
`AsyncError` while the single stream subscription stays the data source. The
provider disables Riverpod 3 automatic retries so the screen's explicit Retry
action controls recovery. Mutations and pushes are ignored after disposal.
Evidence: initial/later error, empty completion, and pending-mutation disposal
tests plus the rendered suite. Remaining: real UI/device retry flow is covered
by the widget suite, not a live backend.

## K15 - Codegen selection prompt does not change the generated setup

**P2 - Observed - codegen.**
The manifest offers a generators multi-select, but declares all generator
dependencies unconditionally. The brick always contains the model that uses
both Freezed and JSON generation; its templates do not reference generators.

**Fix:** either make the selection affect dependencies/templates/tests, or
remove the ineffective choice and explain that both are installed together.
**Accept:** test every advertised selection in a fresh app, run build_runner,
analyze and round-trip the actual generated output; a second run is unchanged.

**Implementation 2026-11-19:** the ineffective `generators` prompt was removed from
the manifest and brick variables; both generators are always installed and the
README/manifest test say so.

## K16 - Remote config refresh can regress and invalid booleans ignore fallback

**P2 - Observed - remote_config.**
Concurrent fetch calls overwrite `_pending` in completion order without a
revision/dedup guard. An older response can become active after a newer one.
getBool returns `value == 'true'` for every String, so an invalid string returns
false even when defaultValue is true. The support probe downloads config and
ready downloads it again. Active state has no restart persistence.

**Fix:** choose latest-request or serialized refresh semantics, make typed
fallbacks consistent, reuse a safe probe result, and decide persistence/TTL.
**Accept:** finish two refreshes in reverse order; old values do not win.
Invalid booleans respect fallback; offline startup preserves documented defaults
or cached state. No endpoint/secret trust escalation is introduced.

**Implementation 2026-11-19:** fetches are serialized with a generation guard so an
older response cannot become the active snapshot after a newer one, and `getBool`
accepts only `true`/`false` strings before falling back.

**Implementation 2026-11-21:** with `storage` installed, every successful fetch is
persisted and a snapshot newer than `cacheTtl` is served when the endpoint is
unreachable, including during the support probe so `ready` still applies it.
Malformed snapshots are dropped and a cache write never fails a fetch. Evidence:
storage-cache and client/module cache tests.

**Implementation 2026-11-22:** a loopback live-endpoint suite now runs the real
`HttpRemoteConfigGateway` against a real `HttpServer`: bootstrap fetch+activate
with probe reuse, a superseded slow response losing to a newer fetch, HTTP 500 as
`unavailable` with the active snapshot kept, timeout as `network.timeout`,
non-JSON as `validation.invalid_input`, and an unreachable endpoint degrading to
defaults with support `unavailable`. Evidence:
[report](remote-config-live-endpoint-2026-11-22.md). Scheduled background
refresh is deliberately not implemented: `fetchInterval` is advisory and the app
owns the cadence.

**Decision 2026-11-22:** app-owned cadence plus an opt-out resume refresh.
`RemoteConfigModule` refreshes on `Lifecycle` resume after the app was
backgrounded for at least `fetchInterval` (and `fetchInterval` has passed since
the last refresh), single-flight, using the injected `Clock`;
`RemoteConfigConfig.refreshOnResume` (default true) disables it. No OS
background scheduling, so no native dependency. `fetchInterval` is documented
as a minimum resume gap, not a timer. Evidence:
[product decisions](product-decisions-2026-11-22.md).

## K17 - Storage migrations can replay partially completed changes

**P1 - Observed/Risk - storage, local_db follow-up.**
StorageMigrator executes multiple migration callbacks and writes targetVersion
only once at the end. If a later migration fails, earlier successful callbacks
run again on retry. Missing callback entries silently advance the version.
BackupExport.import skips malformed records and writes incrementally without
validating the version or rolling back a partially applied import.

**Fix:** define transactional or step-checkpoint/idempotency guarantees, reject
missing migrations where unsafe, and validate backups before mutation.
**Accept:** fail migration N after N-1 succeeds and retry without duplicate/data
loss; unsupported backup versions fail clearly; a malformed backup cannot
silently produce a partly restored database described as successful.

**Implementation 2026-11-19:** `StorageMigrator` snapshots the storage before
each step, restores it when the step throws, writes `schema_version` only after
success, and rejects a missing migration. `BackupExport.import` validates the
version and every record before mutating, then restores previously written
records if a later write fails. Evidence: failed-step retry without replaying
completed steps, missing-migration rejection, unsupported-version, and malformed
record tests plus the rendered suites. Remaining: large-storage snapshot cost
and a live migration on a real app upgrade.

**Implementation 2026-11-20:** each step now writes a recovery checkpoint
(`from`, `to`, snapshot) before running and clears it after the version write, so
a process death inside a step is rolled back and retried on the next start; a
checkpoint whose target version was reached is discarded without restoring, and an
unreadable checkpoint fails clearly. `BackupExport.import` writes a journal of
previous values (status active until commit) and `recover` rolls back an
interrupted import at startup and before the next import. `StorageMigrator` and
`BackupExport` accept a core `MutationLock` for cross-handle/process exclusion.
Evidence: interrupted-step recovery, committed-step leftover, unreadable
checkpoint, crashed-import rollback (idempotent), committed-journal discard,
recover-before-write and lock tests. See
[cross-handle durability](cross-handle-durability-2026-11-20.md).

**Implementation 2026-11-21:** real second processes test the recovery path. A
worker process is killed inside a migration step after writing part of it; the
checkpoint left on disk holds the pre-step snapshot, and a fresh process restores
it, drops the partial key, and completes the step. Evidence:
[multi-process durability](multiprocess-durability-2026-11-21.md). Remaining: the
snapshot/journal cost of a large storage, and recovery cannot detect unrelated
writes made while an import was interrupted.

**Decision 2026-11-22:** documented as a deliberate limit, not changed. Recovery
is already strong; the two remaining limits only matter at scales this SDK does
not target, and the fixes (incremental checkpoints, author tags) add new failure
modes for unproven benefit. A real large-store migration becomes a new finding
with measurements behind it. See
[product decisions](product-decisions-2026-11-22.md).

## K18 - Concurrent sync flushes can deliver the same change twice

**P1 - Observed/Risk - local_db.**
SyncQueue.flush reads pending, calls the handler, then removes each row, with
no in-flight guard or atomic claim. Two callers can process the same snapshot.
Process death after remote success but before remove can also replay a mutation.
Items lack explicit owner/session and retry/claim state.

**Fix:** serialize/claim flush work, define at-least-once delivery, require a
stable idempotency key for remote effects, and decide user-switch ownership.
**Accept:** simultaneous flushes do not independently deliver the same item;
interrupted delivery retries safely; logout/user switch cannot replay user A's
queue under user B without an explicit migration policy.

**Implementation 2026-11-19:** `SyncQueue.flush` is serialized per queue, items
carry an optional `owner`, and the queue documents at-least-once delivery with
`SyncQueueItem.id` as the idempotency key. A handler error leaves the failed and
remaining items pending; a concurrent flush waits and returns zero; `pending`
and `flush` accept an owner filter. Evidence: concurrent-flush, interrupted
delivery, and owner-scoping tests plus the rendered suite. Superseded by the
2026-11-20 implementation below: the durable claim and the cross-process lock now
exist; apps must still adopt owner + idempotency in their handlers.

**Implementation 2026-11-20:** `SyncQueue.flush` accepts a core `MutationLock`
and holds it for the whole flush, so a background isolate, second engine or
desktop instance cannot deliver the same items; the extension ships
`FileMutationLock` and `localDatabaseMutationLock(config)` (advisory OS lock,
released when the process exits; null on web). Every item is also claimed
durably (flush id, timestamp, attempt count): a live foreign claim is skipped, a
claim older than `claimLease` is taken over, and a handler failure releases the
claim immediately. Evidence: two queues over separate database handles sharing one
lock deliver each item once with concurrency one, the file lock releases after an
error, and claim skip/take-over/release tests pass. See
[cross-handle durability](cross-handle-durability-2026-11-20.md).

**Implementation 2026-11-21:** a real two-process suite replaced the manual
check, and it exposed a defect in the lock itself: `FileLock.exclusive` is a
non-blocking attempt on Windows (`LockFileEx` with `FAIL_IMMEDIATELY`) and on
POSIX (`fcntl(F_SETLK)`), so a competing process threw `errno 33` instead of
waiting. `FileMutationLock` now uses `FileLock.blockingExclusive`, so a second
process parks until the holder releases. The suite proves: a real second process
waits (entered only after release), a hard-killed holder does not block the next
writer (the OS releases the lock), three racing processes deliver 24 queued items
exactly once with non-overlapping handlers, a claim left by a killed worker is
kept as live and then taken over after `claimLease` with `attempts=2`, and an
import killed mid-write is rolled back by a fresh handle. Evidence:
[multi-process durability](multiprocess-durability-2026-11-21.md). Remaining: the
lock is advisory, POSIX locks do not exclude two isolates in one process, Windows
locks make nesting the same path in one process wait for itself, and the flush
race test uses a shared durable store rather than concurrent Sembast handles
(Sembast documents single-process access).

## K19 - Retry waiting is not cancellable or bounded by Retry-After limits

**P2 - Observed - http_retry.**
RetryMiddleware awaits a plain delayed Future and does not check cancellation
around the delay. Retry-After can exceed the configured backoff ceiling; now
uses DateTime.now despite injectable clocks elsewhere. Idempotency checks do
not establish that a body/stream is replayable, and an empty Idempotency-Key is
accepted by presence alone. K01 must be resolved before response-policy tests.

**Fix:** add a total time budget, cancellable waits, injected time, validated
retry settings/header values, and a body replay policy.
**Accept:** cancelling during a large Retry-After completes promptly without a
new send; huge/malformed headers are bounded; non-replayable bodies do not
retry; deterministic tests assert actual attempt count and elapsed budget.

**Implementation 2026-11-21:** `HttpRetrySettings.totalBudget` (optional,
off by default) caps one request's retry sequence in wall-clock time using the
injected `Clock`: each wait is clipped to the remaining budget and no attempt
starts once it is spent, so the worst case is no longer `maxAttempts x
maxDelay`. The module accepts `settings`, and `copyWith`/`validate` cover the new
field. Waits were already cancellable and interrupt a large `Retry-After`;
`Retry-After` is clamped to `maxDelay` and now to the remaining budget too.
Evidence: budget exhaustion (response and failure branches), a budget shorter
than the first delay, a `Retry-After` clipped to the budget, no-budget behaviour,
**Implementation 2026-11-19:** ArchiveUnpacker enforces compressed size, entry
count, per-entry size and expanded-size budgets before writing
(`store.archive_too_large`); `RegistryClient` bounds one request with a timeout and a
maximum body; `Verifier` kills a hung process at the timeout. Evidence:
renderer/archive, registry and verifier suites.

**Live acceptance 2026-11-22:** `packages/kiln_store/test/registry_client_live_endpoint_test.dart`
hits a real loopback `HttpServer`: a slow endpoint fails with `store.fetch_failed`
inside the request timeout (well under the server's 2 s hold), an 4 MiB live body
is cut off at the 64 KiB budget, and a valid live index still parses. Evidence:
`dart test` in `packages/kiln_store` (95 tests). Remaining: retry/cancellation UX
for a slow download (optional polish) and a live oversize server beyond loopback.

and settings tests. Remaining: a budget shared across pipeline layers (for
example auth refresh before the retry middleware) would need a per-request
deadline in the `HttpRequest` contract, which is a separate contract decision.

**Implementation 2026-11-21:** `HttpRequest.deadline` is the shared per-request
budget, with `remainingUntil`/`isDeadlineExceeded`/`throwIfDeadlineExceeded`
helpers and the typed `network.deadline_exceeded` code. Retry combines it with
`totalBudget` (the stricter wins), clips waits, and throws once the deadline
passes; Dio rejects an expired request before the transport, clamps
connect/send/receive timeouts and cancels the in-flight call. `TokenProvider`
accepts the same deadline, and REST auth forwards it through the refresh request;
SDK-backed providers accept it as best effort. Evidence: helper/pipeline tests,
retry deadline tests (expired, clipped, success), Dio pre-send/cancel/clamp tests
and the REST auth refresh propagation test. See
[contract decisions](contract-decisions-2026-11-21.md). Remaining: SDK-backed
providers cannot cancel their own refresh; they honour the deadline only where
the SDK exposes cancellation.

**Implementation 2026-11-19:** waits check cancellation before and after the delay,
`Retry-After` is clamped to `maxDelay`, the parser uses an injectable clock, an empty
`Idempotency-Key` is rejected, and non-replayable bodies are not retried.

## K20 - HTTP log URL sanitization retains fragments

**P2 - Observed - logger.**
HttpLogMiddleware._safeUrl clears userInfo/query but retains the URI fragment.
PiiRedactor.redactText only recognizes email/Bearer/JWT patterns, so an opaque
secret in a fragment can remain in the logged URL. Nested Map conversion in the
shared redactor also assumes String keys and has no cyclic/depth policy.

**Fix:** strip fragments and adopt explicit structured limits for log/context
data. Do not log complete signing URLs or user credentials on failure paths.
**Accept:** a URL with an opaque fragment secret never reaches any sink/export;
redaction handles supported nested types and oversize/deep/cyclic inputs without
crashing application logging. Use synthetic secrets in tests.

**Implementation 2026-11-19:** the HTTP log URL strips fragments before redaction,
and the shared `PiiRedactor` bounds depth, entry count and text length (cycles and
non-string map keys included).

**Implementation 2026-11-21:** every sink is wrapped in `LimitedSink`, so the cap
applies whether or not redaction is enabled. `LoggerConfig.maxRecordTextLength`
(16384 by default) bounds the message, error, stack trace and every data string;
structured data is limited to 12 nested levels and 200 entries, and cycles are
replaced instead of followed. The config validates a positive cap. Evidence:
record-limit unit tests plus a module test that disables redaction and still gets
a bounded memory record. See
[composition and log bounds](composed-fixture-2026-11-21.md). Remaining: a
retention policy stays optional.

## K21 - Registry fetch/extraction and verifier processes have no resource bounds

**P2 - Observed/Risk - kiln_store, kiln_extension_sdk, kiln_cli.**
RegistryClient reads complete HTTP bodies without timeout/size limits.
ArchiveUnpacker decompresses full input without entry/count/expanded-size
budgets. Verifier uses Process.run without a timeout/termination policy.
Archive path checks are lexical; the CLI currently extracts into a fresh temp
directory, which reduces existing-link risk. Do not claim that an existing-link
archive exploit was demonstrated. Portable Windows collision/path rules merit tests.

**Fix:** bound download/decompression/process work, clean up partial artifacts,
and define retry/cancellation. Preserve existing checksum, link/traversal rejection,
and transactional RootPath protections; add targeted hardening rather than replace them.
**Accept:** slow HTTP, oversize archives, duplicate/case-colliding paths, and a hung
verifier fail with actionable diagnostics and leave recoverable state.

**Implementation 2026-11-19:** `ArchiveUnpacker` enforces compressed size, entry
count, per-entry size and expanded-size budgets before writing
(`store.archive_too_large`); `RegistryClient` bounds one request with a timeout and a
maximum body; `Verifier` kills a hung process at the timeout. Evidence:
renderer/archive, registry and verifier suites.

**Live acceptance 2026-11-22:** `packages/kiln_store/test/registry_client_live_endpoint_test.dart`
hits a real loopback `HttpServer`: a slow endpoint fails with `store.fetch_failed`
inside the request timeout (well under the server's 2 s hold), a 4 MiB live body is
cut off at the 64 KiB budget, and a valid live index still parses. Evidence: `dart
test` in `packages/kiln_store` (95 tests). Remaining: retry/cancellation UX for a
slow download (optional polish) and an oversize server beyond loopback.

## K22 - Installer transactions do not serialize concurrent CLI writers

**P1 - Risk from observed architecture - kiln_extension_sdk, kiln_cli.**
Transactions journal/snapshot individual operations, but no project-wide process
lock was found in the inspected installer/CLI code. Parallel setup/add/remove
can read the same old lockfile, interleave writes, and roll back another
operation. Journal IDs use timestamps, and journal/project writes are direct
rather than temp-file replace operations. Staging copies nearly the whole project.

**Fix:** implement a recoverable project mutation lock and atomic metadata writes;
audit crash recovery before optimizing the staging copy scope. Read-only commands
should remain useful; avoid stale-lock dead ends.
**Accept:** two independent CLI processes cannot interleave mutations; terminate
one mid-operation and recover without deleting user edits. Large projects and
unrelated assets do not make a no-op setup unexpectedly expensive.

**Implementation 2026-11-19:** a reentrant `ProjectLock` (`.kiln/project.lock`,
exclusive create, stale takeover after 10 minutes, `project.busy` diagnostics) guards
mutations; journal writes use temp-file + rename. `CommandRunner` takes the lock for
`add`, `remove`, `upgrade`, `repair`, `rollback`, `setup <extension>`/`--all`,
`doctor --fix` and `store install`; bare `kiln setup` only reports status and is not
locked.

**Crash-recovery acceptance 2026-11-22:** a child process opens a `Transaction` that
applies half its writes, then is killed; a fresh process finds the running journal
(`Rollback.latestInterrupted`), reverses it, and leaves an unrelated user file
untouched, with no journal left behind. The OS lock is released by process death, so
the next operation is not blocked. Evidence:
`packages/kiln_extension_sdk/test/rollback_test.dart` (184 tests in the package).
Remaining: direct SDK callers own the lock for a series of calls; the upgrade staging
copy is still a full copy and can be optimized later behind the same lock.

## K23 - Some green contract tests exercise only shared fakes

**P2 - Observed - kiln_testing, appwrite, appwrite_push, appwrite_push_native.**
Appwrite's cloudFunctions/pushTargets contract entries instantiate shared fakes.
Both push transport contract files instantiate FakePushTransport. These tests
validate the fake rather than those adapters. PushTransportContract's foreground
test returns early for a transport without the fake emitter, reporting a pass
without delivering a message. Analytics' similarly named FakeGatewayAnalyticsHarness
does instantiate PosthogAnalytics; do not incorrectly classify it as fake-only.

**Fix:** build injectable real-adapter harnesses and report unsupported driver
checks as explicit skips. Keep fakes' own contract tests in kiln_testing.
**Accept:** intentionally breaking the adapter fails its contract test;
delivery paths are driven through a driver seam; live reports distinguish pass,
skip, not configured, and not run. Broaden contracts beyond happy-path CRUD.

**Implementation 2026-11-19:** contract files no longer claim live coverage from
shared fakes. The Appwrite contract skips CloudFunctions/PushTargets, the push and
native-push contracts skip delivery without a platform driver, and
`PushTransportContract` calls `markTestSkipped` when there is no test emitter; fake
coverage moved to `kiln_testing/test/fake_adapter_contracts_test.dart`. Remaining:
injectable real-adapter harnesses for a live project and device broker.

**Live adapter acceptance 2026-11-22:** the two Appwrite adapters now run against
the owner's real project (`6afebe9d000e9c351b3e`, Appwrite 2.7.2) through
`tool/e2e/k23_live_adapters_test.dart.tmpl`, rendered into the Appwrite fixture:
6/6 passed. `AppwriteFunctions` invoked a deployed `node-22` function (200, JSON
body echoed), returned a typed `Failure` for an unknown function and rejected a
non-HTTP method locally; `AppwritePushTargets` created a real push target against
a real FCM provider, showed that re-register is an upsert by id, updated and
removed it, and rejected empty input with typed failures. Without the
environment variables the group reports an explicit skip, never a pass. The
temporary function, FCM provider, platform and user were deleted (`204` each).
Evidence: [k23-live-adapters-2026-11-22.md](k23-live-adapters-2026-11-22.md).
Remaining: FCM delivery end-to-end on a physical device (`dev.tegar.appwrite_demo`)
and the device MQTT broker path.

**FCM delivery acceptance 2026-11-23 (emulator):** `appwrite_push`'s FCM
transport received real Appwrite Messaging pushes on `emulator-5554`
(`dev.tegar.appwrite_demo`) in foreground and again after the app card was
swiped out of recents (process gone, Android restarted it from the FCM
broadcast, tray notification shown). Emulator only, so this is not
physical-device evidence and the device row stays open.

The pass also found an **Appwrite 2.7.2 routing defect** and a matching gap in
the extension. With more than one push provider in a project, a target
registered with `providerId: null` (what the client creates) is not delivered
to, while the message still reports `status: sent`, `deliveredTotal: 1` and
`deliveryErrors: []`; `GET /messaging/messages/{id}/targets` returns `total: 0`
and the device receives nothing. Binding the same token to a target with an
explicit FCM `providerId` delivers within seconds. A second project with a
single push provider delivered to a `providerId: null` target first try, which
isolates the trigger to provider-count ambiguity.

Extension gap: `AppwritePushTransport.initialize()` calls `PushTargets.register`
without `providerId`, and `AppwritePushModule` has no provider option, so a
client cannot bind its token to a provider. Candidate fixes (owner decision,
not implemented): a module `providerId` option, an explicit "one provider per
project" requirement in the docs, or an upstream report. Also observed, not
blocking: notification-payload pushes render on the platform fallback channel
because no default channel is set, and notification taps open the app without
surfacing the payload (`onMessageOpenedApp`/`getInitialMessage` unused).
Evidence: [fcm-push-emulator-2026-11-23.md](fcm-push-emulator-2026-11-23.md).
Remaining: physical Android device, iOS/APNs, MQTT broker, Doze/reboot and
token-rotation against a provider-bound target.

## K24 - Setup masks secrets but persists their literal values

**P2 - Observed/Decision - kiln_cli, kiln_extension_sdk, env/backends.**
Setup explicitly warns that masked prompt values are saved in kiln.yaml and may
appear in generated source. ProjectContext writes literal answers. This is a
known design tradeoff, not an undisclosed new leak. Generic PromptType.secret
can still encourage a user to paste a privileged server key into a client setting.

**Fix:** distinguish public client identifiers from runtime secrets/server-only
credentials; support environment references or a local ignored secret source
where appropriate, including migration/rotation and backup behavior.
**Accept:** secret values are absent from reports/errors/command examples, and
the documented mechanism keeps server credentials out of client artifacts and
tracked configuration. Preserve existing masking and explicit warnings.

**Implementation status:** deferred by design. `kiln setup` persists literal masked
answers; migrating to environment references or a secret source is an owner decision.

**Defect 2026-11-22:** the `env:NAME` secret reference rendered
`String.fromEnvironment('NAME')` as a default parameter value, which is not a
constant, so the generated `analytics_config.dart` and `crash_report_config.dart`
failed `flutter analyze` with `non_constant_default_value`. The documented
secrets-out-of-source path therefore produced a project that did not compile.
The `dio` and `env` bricks were unaffected because they render the same
expression into a `static const`.

**Fix 2026-11-22:** `buildTemplateVars` now emits
`const String.fromEnvironment(...)` for `env:` references, so it is valid as a
constructor default and still valid as a `static const`. Goldens for `analytics`
and `crash_report` regenerated; `template_vars_test` and the `kiln setup`
command test assert the `const` form; a freshly generated app with `env:` secrets
passes `flutter analyze`.

## K25 - SocialCredential conflates provider and backend credentials

**P1 - Observed/Decision - kiln_core, social_login, auth backends.**
The contract has idToken/accessToken but no raw nonce or authorization-code
field. Apple gateway generates a nonce, sends its hash, and drops the raw nonce
from the returned value; it puts Apple's authorization code in accessToken.
Appwrite/Supabase browser flows put backend session tokens in idToken, and
Firebase returns a Firebase user ID token. These are different token audiences.

**Fix:** separate obtaining provider credentials from establishing a backend
session, explicitly model token audience/type and nonce/code exchange needs,
and introduce a compatible migration. Do not send one backend's token as a
provider token merely because the field name is the same.
**Accept:** Google/Apple credential acquisition and backend exchange tests assert
audience, cancellation, nonce ownership, and which layer changes AuthRepository.
Document any social_login service that intentionally only acquires credentials.

**Implementation 2026-11-19:** `SocialCredential` now carries `audience`
(provider/backend), `backendSessionToken`, `rawNonce`, and `authorizationCode`
with `copyWith`. Apple returns the raw nonce and authorization code as dedicated
fields instead of overloading `accessToken`; Appwrite and Firebase mark their
session/ID tokens as backend and expose them through `backendSessionToken`;
Supabase keeps the provider token and the Supabase session token separate on
both the legacy and new `credentialSource` paths and labels the browser OAuth
result as backend. `social_login` documentation explicitly describes it as
provider-credential acquisition. Evidence: Apple nonce, Supabase
credential-source/legacy, Appwrite/Firebase audience tests, the shared contract,
and rendered suites. Remaining: live Google/Apple SDK flows and backend
exchanges on devices.

## K26 - Geolocation normalizes only timeout failures in the SDK gateway

**P2 - Observed - geolocation.**
GeolocatorGateway.current catches TimeoutException only; service-disabled,
permission-changed, and platform errors can escape raw. updates maps values
but not stream errors, and support checks cannot prevent permission/service
changes occurring just after the check.

**Fix:** apply one failure mapper to synchronous, Future, and stream failures;
validate accuracy/distance settings and document service/permission recovery.
**Accept:** revoke permission/disable service between precheck and request;
direct contract callers receive typed failures, and cancelled streams release
the native subscription. Verify actual platform behavior separately.

**Implementation 2026-11-19:** every geolocator Future and stream error is mapped
through one failure mapper (service disabled, permission denied, timeout, unknown),
and a negative distance filter is rejected. Evidence: mapper unit tests plus the
rendered geolocation suite. Remaining: device permission/service race tests.

**Device evidence 2026-11-22:** on the physical phone (`c7d2692b`, Android 13)
`current()` and `updates()` returned typed failures in every state: service off
and permission revoked gave `Failure(unavailable, unavailable)`, service on with
permission denied gave `Failure(permission.denied, permission)`. Disabling the
service while the app was running turned ticks 1–2 (`ok`) into ticks 3–10
(`unavailable`) without killing the process, and re-enabling it restored `ok`
without a restart — so the mapper runs per call, not only during bootstrap. See
[device acceptance](geolocation-deeplink-device-2026-11-22.md). Remaining: the
iOS permission/service race and a mid-run permission revoke on a build where
revoking does not kill the app.

## K27 - Theme/locale preference operations can overwrite newer user choices

**P2 - Observed/Risk - theme, l10n.**
Both controllers load asynchronously and later assign the stored value, without
checking for an intervening set operation or disposal. Concurrent persistence
writes have no serialization. Theme setMode claims best-effort persistence but
propagates write errors, unlike LocaleController's documented suppression.

**Fix:** define consistency and error policy, serialize persistence, and guard
late load/write completion and notifier disposal.
**Accept:** begin load, choose a different mode/locale, then complete the old
read; the user's new choice wins. Restart sees the last chosen value; disposal
and storage failures follow the documented contract.

**Implementation 2026-11-19:** theme and locale controllers serialize persistence
writes; a delayed load cannot overwrite a newer choice or a disposed notifier.
Remaining: define/verify the storage-failure copy for theme vs locale.

**Decision 2026-11-22:** report durability instead of hiding it. New core type
`PersistOutcome { persisted, sessionOnly, notConfigured }`;
`ThemeModeController.setMode` and `LocaleController.setLocale`/`followSystem`
return it (the choice still applies for the session), the gate verbs now return
`Result<PersistOutcome>`, and shared ARB copy `preferenceNotSaved` covers the
`sessionOnly` case for both. Evidence:
[product decisions](product-decisions-2026-11-22.md).

## K28 - Image size limit is checked after reading the entire file

**P2 - Observed - image_picker.**
DeviceMediaPicker.fromFile reads all bytes before ImageValidator checks maxBytes.
An oversized gallery/lost-data file can allocate well beyond the configured
limit even though it is eventually rejected. Extension/MIME sniffing alone is
not a complete image-decode/dimension validation policy.

**Fix:** check reliable length before full read, consider bounded streaming and
decoded dimension limits, and keep lost-data recovery under the same validation.
**Accept:** a file larger than maxBytes is rejected without reading its full
contents; valid files preserve MIME/name/size, and cancellation stays distinct
from validation or permission failure.

**Implementation 2026-11-20:** length and streamed bytes are bounded before the
full read (as before), and the encoded header is now parsed to reject an image
whose intrinsic size exceeds `maxDecodedWidth`/`maxDecodedHeight`/
`maxDecodedPixels` before a decoder allocates it; the measured size is exposed on
`PickedImage`. Formats are PNG, JPEG, GIF, WebP and the AVIF/HEIC `ispe` box; an
unmeasurable header is skipped because it cannot decode to a bitmap. Evidence:
header readers over real and synthetic fixtures, validator policy tests, picker
tests, and the rendered suite. See
[media dimension limits](media-dimension-limits-2026-11-20.md). Remaining: real
device acceptance with the plugin (including HEIC from an iPhone), and a lying
header is only caught by the decoder.

**Remaining after the 2026-11-20 dimension work:** a shared lost-data/upload policy
test was added on 2026-11-22 (`media_policy_test.dart`): a recovered image goes
through the same converter as a direct pick, so the byte and decoded-dimension
limits reject it identically, a valid recovered image uploads with its detected
content type, and cancelled/denied outcomes stay distinct from validation
rejection (`mediaCancelled`/`mediaPermissionDenied` versus `mediaInvalid`).
**Device evidence 2026-11-22:** with the real plugin and system UI on the
physical phone, a gallery pick returned a 14 KB downscaled JPEG with
`dims=800x600` from the encoded header, a gallery cancel returned `null` (not a
failure), lost-data recovery returned `null` with nothing pending, and — with
the owner's explicit approval — a camera capture returned a 162 KB JPEG at
`1600x1200`, the configured target, inside the 5 MB limit; a camera cancel
returned `null`. See [device acceptance](image-picker-device-2026-11-22.md). A
second run with `max_bytes: 102400` and a pushed 6 MB noise PNG rejected the
picked file with `Failure(media.invalid, validation)`, so the byte bound holds
against a real picked file.

Still open: HEIC from an iPhone and iOS picker behaviour.

## K29 - Custom-scheme deep links bypass configured host/path restrictions

**P2 - Observed/Decision - deep_link, go_router.**
LinkAllowlist allows the configured custom scheme immediately; host/path
restrictions apply only to https. This may be intentional, but a user configuring
pathPrefixes can reasonably expect the same routing boundary for custom links.
AuthRedirect sees only a Boolean authenticated value and cannot express unknown
versus signed-out session state; intended destination persistence needs review.

**Fix:** explicitly define which restrictions apply to custom schemes and which
routes are public/protected/loading. Validate route parameters before actions.
**Accept:** custom/https links outside intended boundaries are rejected according
to policy; startup auth restoration and login preserve the intended safe route
without redirect loops or accepting arbitrary external return destinations.

**Implementation 2026-11-22:** custom-scheme links are no longer exempt from the
boundary. `LinkAllowlist` applies configured path prefixes to the custom scheme
(deriving the path from host+path when the link has an authority), enforces
optional `customSchemeHosts`, rejects ports and schemeless custom forms, and
strips tracking parameters and fragments before matching. `AuthRedirect` is
tri-state over `SessionStatus` — `unknown` keeps a loading route instead of
treating the visitor as signed out — and the `returnTo` destination is
sanitized to a local path. Evidence: allowlist tests (custom-scheme prefixes,
custom hosts, traversal/encoded separators), rendered go_router suite, and
native delivery on the physical phone
([device acceptance](geolocation-deeplink-device-2026-11-22.md)): cold-start
`kiln://app/profile/42` and warm `kiln://app/orders/7` reached the app, while
`kiln://other/secret/9`, `kiln://evil/../admin`, `https://evil.example/app/x`
and `https://kiln.dev.evil.example/app/x` were dropped. Remaining: iOS native
delivery.

## K30 - Stale cache refresh can repopulate invalidated data

**P2 - Risk from observed code - http_cache.**
CacheInterceptor starts unawaited stale revalidation. A mutation can complete
and invalidate the same tag before an older GET finishes; `_refresh` then stores
that old result with a fresh timestamp. No invalidation generation/conditional
write exists in this path. Storage cache eviction uses the first enumerated key,
not a defined LRU order, and cache-store errors can turn a successful HTTP
exchange into a failed call unless deliberately handled.

**Fix:** fence refresh writes by invalidation revision, deduplicate revalidation,
and define cache failure/eviction policy. Preserve current auth-header/no-store/
private/Vary restrictions, which already exist; do not report them as absent.
**Accept:** delay a background GET, mutate/invalidate, complete the old GET, and
verify it cannot become the new cached truth. Test actual Dio composition after
K01, including 304 headers and cancellation.

**Implementation 2026-11-19:** The interceptor keeps a per-path invalidation
revision; mutation responses bump it, and any store (foreground or background
refresh) whose request started under an older revision is skipped. Overlapping
stale reads share one revalidation per key, cache reads/writes/invalidations are
best effort, and the storage cache evicts the oldest `storedAt`. Evidence:
delayed-refresh vs mutation, refresh deduplication, existing 304/cancellation
tests, and the rendered suite. Superseded by the 2026-11-21 implementation
below: the composed fixture now exists.

**Implementation 2026-11-21:** the composed fixture is built
(`tool/e2e/dio_cache_probe.dart`): a real Dio transport, pipeline and cache
interceptor against a loopback server prove cache hits, `no-store`, mutation
invalidation (delayed-refresh collision is covered by the interceptor's revision
guard and its rendered tests), range bypass and ETag revalidation. See
[Dio + cache composition](dio-cache-composition-2026-11-20.md).

## K31 - Partial HTTP responses can occupy the full-response cache key

**P1 - Observed/Risk - http_cache.**
Default cacheable statuses include 206. CacheKeyBuilder's default vary headers
do not include Range, and HttpCachePolicy does not reject Range requests or
206 responses. A partial GET without an explicit incompatible Vary header can
therefore use the same key as a full GET or a different byte range.

**Fix:** bypass range/partial responses until correct range-aware storage and
validation exists, or implement a complete partial-response policy. Do not
simply add Range to a key while leaving full-response/conditional semantics vague.
**Accept:** cache bytes 0-9, then request the full resource and bytes 10-19;
neither receives the first partial payload as a valid full/other-range response.
Add a local HTTP server case after the policy regression.

**Implementation 2026-11-19:** `HttpCachePolicy` now bypasses requests with
`Range`/`If-Range`, rejects `206` and any `Content-Range` response even when a
custom settings set includes 206, and the default cacheable statuses no longer
contain 206. Evidence: range/full/other-range regression and the rendered
suite. Superseded by the 2026-11-21 note below for the composition case;
range-aware caching is deliberately deferred rather than keyed by Range.

**Implementation 2026-11-21:** the composed case now exists:
`tool/e2e/dio_cache_probe.dart` renders `dio` and `http_cache` together and runs
five scenarios against a real loopback `HttpServer` with the real transport,
pipeline and cache middleware (repeat read from cache, `no-store`, mutation
invalidation, `Range` bypass that leaves the full entry intact, and
`If-None-Match`/304 revalidation). See
[Dio + cache composition](dio-cache-composition-2026-11-20.md). Remaining:
range-aware caching is still intentionally deferred.

## K32 - Add/remove verification is outside their normal commit boundary

**P1 - Observed - kiln_extension_sdk, kiln_cli.**
The direct ExtensionInstaller.add path commits its transaction before invoking
Verifier. The direct remove path has the same ordering if verification is
enabled; CLI remove defaults to no verification. AddCommand writes saved answers
after the installer returns and before checking verification failure. Those
answer writes are outside the installer's journal. RemoveCommand similarly
deletes saved answers outside that transaction and does not check a verification
result. Setup/upgrade/removeBatch have stronger staged flows; do not assume that
their guarantees automatically apply to direct add/remove or CLI remove.

**Fix:** define and apply one commit-after-verification boundary that includes
source, native patches, pubspec/pub lock, Kiln lock and saved answers. Make CLI
success/failure and JSON output match committed state. Decide whether remove
verification is required or explicitly optional, with a safe default.
**Accept:** force pub-get/analyzer failure and verifier exceptions during add
and verified remove; all managed state including kiln.yaml returns to the
pre-operation state. A successful add followed by rollback also restores saved
answers. Include direct SDK and CLI-level tests, not just setup tests.

**Implementation 2026-11-19:** Direct `add`/`remove` run verification inside the
installer-owned transaction and commit only on success; saved answers are
written or removed in that same transaction via `persistAnswers`, and rollback
restores `pubspec.lock`. CLI add/remove/store use a ProcessRunner-backed
verifier, report `status`/`committed`, and never print success after rollback;
remove verification is explicitly opt-in with `--verify`. Evidence: installer
tests for verification failure, verifier exceptions, and verified remove; CLI
add/remove/rollback tests including JSON state; full CLI suite. Remaining: the
project-wide mutation lock (K22) and process bounds (K21) are separate findings.

## K33 - One CLI cancellation message still violates the English SDK preference

**P2 - Observed - kiln_cli.**
RemoveCommand's rejected confirmation logs `Dibatalkan.`. The owner's preference
is English SDK/CLI content, with Indonesian conversational reports.

**Fix:** change shipped CLI copy consistently and cover cancellation output.
Search for remaining fixed Indonesian SDK strings, while preserving intentional
localized l10n fixtures and tests that demonstrate a backend-supplied message
in another language. Do not translate user data or remove localization coverage.
**Accept:** cancellation and error/help output are English; localization tests
continue to prove the supported languages and backend-message handling.

**Implementation 2026-11-19:** the remove confirmation message is English
(`Cancelled.`); a repository search found no other fixed Indonesian CLI copy.

