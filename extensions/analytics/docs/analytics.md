# Analytics

`Analytics` records product events and identifies users. Its contract lives in
`kiln_core`; this extension provides the PostHog implementation.

## Configuration

Initial values come from the install prompt:

- `api_key`: PostHog project API key. Leave it empty to disable analytics
  without changing application code.
- `host`: PostHog ingest host, default `https://us.i.posthog.com`.

`AnalyticsConfig` also controls `flushInterval` and `enabledFlavors`. The default
interval is 30 seconds and all standard flavors are allowed. Narrow the flavor
list when development events must not be sent:

```dart
final config = AnalyticsConfig.defaults.copyWith(
  enabledFlavors: const <AppFlavor>{AppFlavor.production},
);
```

The module uses `NoopAnalytics` when the API key is empty, `enabledFlavors` is
empty, or the current `AppFlavor` is not in the list. SDK setup runs on a best
effort basis: a PostHog failure does not stop the application.

## Usage

```dart
final analytics = registry.read<Analytics>();

await analytics.capture(
  'project created',
  properties: <String, Object?>{'plan': 'pro', 'seats': 3},
);

await analytics.identify(session.userId, traits: <String, Object?>{
  'role': 'owner',
});
```

`capture`, `identify`, and `reset` throw a `Failure` when the SDK fails. If the
caller does not want to handle analytics failures, wrap the call with
`Result.guard` or ignore the failure; analytics is not the application's main
flow.

## Session identity

`SessionIdentityListener` is already registered and run by the module. When
`SessionController` has a non-null session, the listener calls `identify` with
the `userId`; when the session becomes null, the listener calls `reset`. The
listener never throws an error into the sign-in flow.

## Replacing the gateway

All plugin access sits in `AnalyticsGateway`. The SDK implementation is
`SdkPosthogGateway`; tests use a fake gateway. For another vendor, replace the
gateway and `PosthogAnalytics` without changing the consent or PII decorators.

See [event-naming.md](event-naming.md) and
[privacy-and-consent.md](privacy-and-consent.md).
