# Changelog

## Unreleased

- Reject `Registry.unregister` after disposal, matching every other mutator, so
  it cannot race the owned-disposal pass and the container reset.

## 0.1.1

- Report dependent modules as unavailable when their provider is filtered by
  platform. Required startup modules receive typed support failures.
- Concurrent registry disposal callers share completion and cleanup errors.
- Document the fields that participate in `Failure` equality.

- Expose `PersistOutcome` so preference APIs can distinguish a persisted
  setting from a setting applied for the current session.

- Add an optional `HttpRequest.deadline` with a typed
  `network.deadline_exceeded` failure. `TokenProvider.accessToken` accepts the
  same deadline so a refresh can carry the caller's budget.
- Add `Registry.registerOwned` and `Registry.dispose` for opt-in ownership;
  `KilnBootstrap` disposes owned services after module disposal. An unavailable
  support result for a required module, or missing required startup
  capabilities, produces a typed `Failure`.
- Add the optional `MutationLock` contract and the in-isolate
  `SerialMutationLock`, so a queue, migration or import can declare the exclusion
  it needs without depending on a platform package.

- Add the optional PushNotificationOpens interface for generic push tap routing,
  without changing existing PushTransport implementations.
- Add the optional PushDeliveryControls interface and PushDeliveryStatus model,
  so an application can read the transport's background-delivery guarantees and
  ask for the Android exact-alarm and battery-optimisation exemptions from a
  user action instead of silently losing messages.
- Bootstrap honors required startup modules/capabilities and unavailable hard
  dependencies. Readiness callbacks only report supported modules; support
  results arriving after disposal are ignored.

- Bound recursive PII redaction by depth, node count, and text size; cyclic
  collections and non-string nested map keys no longer break logging.

- `SocialCredential` now models token audience, the backend session token, the
  raw nonce, and the provider authorization code so provider and backend
  credentials are no longer conflated.
- `FileStorage.url` documents that `expiresIn` is a requested capability: an
  implementation that cannot issue expiring links must reject it instead of
  silently returning a permanent link.
- `HttpCancelToken.onCancel` notifies a transport when a request is cancelled,
  so an in-flight request can abort instead of only failing the next check.
- Bootstrap registers a per-registry `Gate` before initializing modules,
  matching the test registry. Manual `Gate(registry)` construction still works.
- Gate verbs resolve their contract inside the guard, so a missing extension
  returns `Err(configurationMissing)` instead of throwing.
- `LifecycleController.dispose` now owns module shutdown, is idempotent, and
  disposes modules that fail during registration.

## 0.1.0

- Initial release.
