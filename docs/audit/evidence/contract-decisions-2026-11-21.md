# Contract decisions: HTTP deadline, startup policy, registry ownership

Date: 2026-11-21 (Asia/Jakarta). No commit or deployment was made. Implements the
three open decisions from [status](../current-status.md): K19, K13, K10.

## K19 - shared request deadline

`HttpRequest.deadline` is an optional absolute wall-clock deadline for one
exchange. Helpers `remainingUntil(now)`, `isDeadlineExceeded(now)` and
`throwIfDeadlineExceeded(now)` give every layer the same rule; an expired request
throws `Failure(network.deadline_exceeded)` (new stable code).

Enforcement:

- **Retry**: combines the request deadline with `HttpRetrySettings.totalBudget`
  and uses the stricter remaining time. Waits are clipped to it; once the
  deadline passes, retry throws the typed failure instead of sending again. A
  budget-exhausted retry keeps its previous behaviour (last response/failure).
- **Dio**: rejects an expired request before touching the transport, clamps the
  connect/send/receive timeouts to the remaining time, and starts a timer that
  cancels the Dio call. A cancelled transport caused by the deadline maps to the
  deadline failure, not `cancelled`.
- **Auth refresh**: `TokenProvider.accessToken` accepts the same deadline.
  REST auth forwards it into the refresh `HttpRequest`, so the original caller's
  budget covers the refresh. Appwrite/Supabase/Firebase token providers accept
  the parameter as best effort; their SDKs do not expose request cancellation.
- A cache hit can still be served after the deadline because it needs no network
  work. A layer that constructs a follow-up request is expected to copy the
  deadline.

Tests: core deadline helpers/typed failure/copyWith; retry expired/clipped/
successful-retry cases; Dio pre-send/cancel/timeout-clamp cases; REST auth
refresh-carries-deadline. The full core suite passed (186 tests).

## K13 - startup policy and cancellation boundary

The policy is now explicit and typed:

- A module with `requiredForStartup: true` stops bootstrap with the `Failure`
  derived from its support state: `configuration.missing` for `notConfigured`,
  `unavailable`, or the matching `support.*` code. Missing required capabilities
  throw a typed `unavailable` failure containing the missing capability list.
  Everything already registered is disposed in reverse order.
- An optional module stays registered, loses its capability, and skips `ready`.
  A dependent that requires a missing capability skips `ready` as well and
  records why; unrelated modules still start.
- `Future.timeout` bounds the wait only. It cannot cancel a plugin or transport
  call; modules must fence late completions after disposal. Cancellation is
  cooperative and available only through contracts that expose it (Dio cancel
  token, the HTTP deadline). This boundary is now documented in `KilnModule`,
  `docs/reference/core-runtime.md`, and the status page instead of being an
  implicit convention.

Tests: required-unavailable and required-notConfigured typed failures,
dependent-readiness skip, unrelated-module readiness, and the existing
late-initialization fencing suite.

## K10 - registry ownership

`Registry` gained opt-in ownership:

- `registerOwned<T>(instance, {dispose})` registers a singleton and records its
  disposal callback. Without a callback, a `Disposable` instance's `dispose()` is
  inferred.
- `dispose()` runs owned callbacks once, in reverse registration order, attempts
  every callback even when one throws, then clears all registrations. Calling it
  again is a no-op.
- `KilnBootstrap` adds `registry.dispose()` to the lifecycle before module
  callbacks, so reverse-order shutdown disposes modules first and the registry
  last.
- Plain `registerSingleton` is unchanged and remains the caller's responsibility,
  so a resource a module already disposes is never double-disposed.
- Registering after disposal throws `StateError`.

Tests: reverse order, idempotence, inferred `Disposable`, registration-after-
dispose rejection, one failing callback not skipping the rest, and a bootstrap
test that disposes a registry-owned service on lifecycle shutdown.

## Verification

- `packages/kiln_core`: 191 tests passed (new deadline, registry and bootstrap
  coverage included).
- Rendered suites: `http_retry`, `dio`, `rest_auth`, `appwrite`, `firebase`,
  `supabase` and `secure_storage` analyzed and passed after the shared
  `TokenProvider` change; Appwrite was rerun after the shared registry import
  fix.
- Composed fixture: `flutter analyze` clean (14.4 s) and its 3 tests passed.
- `tool/verify_http_stack.dart`: 6 loopback HTTP tests passed.
- CLI suite: 160 tests passed. `dart analyze`, extension lint, goldens, catalog
  docs, bundle and registry checks all passed; metadata, versions and docs
  (96 files) are consistent.

## Remaining limits

- SDK-backed token providers cannot cancel their refresh; they accept the
  deadline but honour it only where the SDK supports cancellation.
- `Future.timeout` still cannot cancel a plugin call; fencing is the boundary.
- Only services registered with `registerOwned` are disposed by the registry;
  `unregister` does not transfer ownership.
