# Changelog

## 0.1.1

- Add an optional `HttpRequest.deadline` with a typed
  `network.deadline_exceeded` failure. `TokenProvider.accessToken` accepts the
  same deadline so a refresh can carry the caller's budget.
- Add `Registry.registerOwned` and `Registry.dispose` for opt-in ownership;
  `KilnBootstrap` disposes owned services after module disposal. Required
  modules and missing required capabilities now fail bootstrap with a typed
  `Failure` instead of a `StateError`.
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
