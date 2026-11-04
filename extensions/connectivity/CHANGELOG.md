# Changelog

## 0.3.0

- Wire the optional `ReconnectTrigger` and `HttpClient` from the registry into
  `DeviceNetworkMonitor` so documented reconnect actions actually run.
- Add `probeReachability()` and the `networkReachable` gate verb so the
  `probe_url`/`probe_timeout` settings are used; the probe now honors its
  timeout.
- Fix the connectivity doc to reference the `changes` stream.

## 0.2.0

- Removed `OfflineBanner` and `NetworkStatusBuilder`. Applications observe `NetworkMonitor` and render their own connectivity UI.

## 0.1.1

- Add `ConnectivitySupport` and report platform/plugin availability through
  `SupportRegistry`.
- Record an `unavailable` support state when monitoring cannot start.
- Allow `DeviceNetworkMonitor.start` to retry after a failed attempt.

## 0.1.0

- Initial connectivity monitor, stabilizer, offline guard, probe, and widgets.
