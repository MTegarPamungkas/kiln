# connectivity

Monitors network status and provides `offline_guard` for HTTP.

- `NetworkMonitor` from `kiln_core` is implemented on top of
  `connectivity_plus`.
- Status is stabilized with a `Debouncer` so Wi-Fi that goes up and down does
  not trigger excessive changes.
- `ReconnectTrigger` runs pending actions when back online.
- `OfflineGuardMiddleware` (priority 5) stops requests while offline.
- `OfflineBanner` and `NetworkStatusBuilder` are ready to use in the UI.
- `ReachabilityProbe` optionally uses `HttpClient` to check the server.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
