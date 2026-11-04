# connectivity

Monitors network status and provides `offline_guard` for HTTP.

- `NetworkMonitor` from `kiln_core` is implemented on top of
  `connectivity_plus`.
- Status is stabilized with a `Debouncer` so Wi-Fi that goes up and down does
  not trigger excessive changes.
- `ReconnectTrigger` runs pending actions when back online.
- `OfflineGuardMiddleware` (priority 5) stops requests while offline.
- Applications observe `NetworkMonitor` and render their own connectivity UI.
- `ReachabilityProbe` optionally uses `HttpClient` to check the server.

## Gate

```dart
final status = gate.network.status;      // NetworkStatus
gate.network.changes.listen(print);      // Stream<NetworkStatus>
final reachable = await gate.networkReachable(); // Result<bool> (needs probe_url)
```

Synchronous access through the facade; the app renders connectivity UI itself.
`networkReachable` probes the optional `probe_url` through the HTTP client.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
