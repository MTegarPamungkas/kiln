# Testing and rollouts

Remote config is a sync read over an explicit snapshot. Tests should control the
snapshot, not the network.

## Gate import

The typed flag verbs come from the extension gate:

```dart
import 'package:my_app/extensions/remote_config/gate_remote_config.dart';
```

`gate.fetchRemoteConfig()` and `gate.remoteConfig` come from `kiln_core`; the
extension adds `featureEnabled`, `remoteConfigInt/Double/String/Json`,
`setRemoteDefaults`, and `remoteConfigChanges`.

## Test with a fake source

```dart
final config = FakeRemoteConfig();
final registry = createTestRegistry(remoteConfig: config);

config.seed({'beta_checkout': true, 'daily_limit': 10});
await config.fetchAndActivate();

expect(gate.featureEnabled('beta_checkout'), isTrue);
expect(gate.remoteConfigInt('daily_limit'), 10);
```

`FakeRemoteConfig` also supports failing a fetch. Assert that the app keeps
serving defaults and does not crash.

## Rollout rules

- Fetch and activate during bootstrap `ready`. A failed fetch keeps the app on
  defaults and reports `unavailable`; it does not block startup.
- Keep the JSON flat and small: `{"flag": true, "limit": 10}`. Typed getters
  coerce strings, but a flat map is easier to cache and inspect.
- Call `setRemoteDefaults` once at bootstrap so the first cold start has
  deterministic values.
- Gate new UI behind a flag, but keep a safe default that the app can ship with
  if the service is missing.
- Use `remoteConfigChanges` to rebuild flag-driven state; the app still owns the
  widgets.

## Flavors and empty endpoints

`enabledFlavors` limits which builds may hit the network. An empty endpoint with
`noopWhenEndpointEmpty` yields defaults only and is reported as unsupported by
`kiln doctor`, so the extension can be installed before the service exists.

## Production checklist

- Serve the JSON over HTTPS with cache headers appropriate for flags.
- Version or namespace keys; remove old keys after the rollout window.
- Log flag values with PII scrubbing, not raw user identifiers.
- Test the default path, the fetch-failure path, and an unknown key.
