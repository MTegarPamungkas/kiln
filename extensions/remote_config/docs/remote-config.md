# Remote config

`remote_config` gives apps a single, vendor-neutral way to read feature flags and
tunable values at runtime. It implements the `kiln_core` `RemoteConfig` contract
over a gateway; the shipped gateway fetches a flat JSON object from an HTTP
endpoint.

## Why vendor-neutral

Most apps already have *some* place that serves JSON — a config service, a CDN
file, a backend `/flags` route, or an exported Firebase config. Rather than bind
the SDK to one provider, `remote_config` speaks to any of them and keeps the
application code identical. A Firebase- or LaunchDarkly-specific gateway can be
added later by implementing `RemoteConfigGateway`.

## Reads are synchronous, writes are explicit

Feature-gating code must never await the network, so `getBool`/`getInt`/...
return immediately from an active snapshot layered over `setDefaults`. Refreshing
is an explicit `fetch`/`activate` (or `gate.fetchRemoteConfig()`), and `changes`
emits when a new snapshot is activated.

## Empty endpoint

With an empty endpoint the extension is a no-op that serves only defaults, and
`kiln doctor` marks it unsupported without any network call — safe to install
before the config service exists.
