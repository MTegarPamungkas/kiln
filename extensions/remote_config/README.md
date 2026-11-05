# Remote Config

Feature flags and remote configuration for Kiln apps. `remote_config` implements
the `kiln_core` `RemoteConfig` contract over **any JSON HTTP endpoint**, so it is
not locked to a vendor — point it at your own config service, a CDN JSON file, or
Firebase's exported config, and read flags synchronously through the Gate.

It is a real connector extension: it registers a `RemoteConfig` service and the
SDK owns no UI. Flags are cached locally; reads never block on the network.

## Install

```sh
kiln add remote_config
```

The installer prompts for a JSON **endpoint**. Leave it empty and the extension
becomes a no-op that serves only your code-side defaults, so you can adopt it
before the service exists.

## Configuration

`RemoteConfigConfig` is rendered from the prompt:

- `endpoint` — absolute URL returning a flat JSON object of values.
- `fetchInterval` — suggested background refresh cadence.
- `requestTimeout` — per-request timeout.
- `enabledFlavors` — flavors allowed to hit the network.
- `noopWhenEndpointEmpty` — empty endpoint yields defaults only.

## Usage

```dart
final gate = ...; // your Gate

// Sync feature checks over the active snapshot.
if (gate.featureEnabled('beta_checkout')) { ... }
final limit = gate.remoteConfigInt('daily_limit', defaultValue: 10);

// Refresh from the source (single Result call).
final result = await gate.fetchRemoteConfig();

// React to config updates.
gate.remoteConfigChanges.listen(() => rebuildUi());
```

The endpoint must return a JSON object such as:

```json
{ "beta_checkout": true, "daily_limit": 10, "banner": "spring" }
```

## Behavior

- An initial fetch+activate runs during bootstrap `ready`; if it fails the app
  still boots and serves defaults.
- Empty endpoint or a non-enabled flavor marks the extension unsupported in
  `kiln doctor`, without reaching the network.
- To target Firebase Remote Config or LaunchDarkly specifically, add a
  `RemoteConfigGateway` implementation for that backend.
