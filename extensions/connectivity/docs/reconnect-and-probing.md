# Reconnect and probing

Connectivity is more than "is Wi-Fi on": the device can be online while your
server is unreachable. The extension exposes both signals.

## Monitor status

```dart
final monitor = registry.read<NetworkMonitor>();
final status = monitor.status; // unknown at first
final subscription = monitor.changes.listen((status) {
  if (status == NetworkStatus.offline) showOfflineBanner();
});
```

`unknown` is the initial state before the platform answers. The monitor
debounces rapid changes so a flapping connection does not trigger a rebuild
storm.

## Run work on reconnect

```dart
final trigger = ReconnectTrigger(
  onReconnect: () => queue.flush(),
);
```

Register it before bootstrap; `DeviceNetworkMonitor` updates it when the status
transitions from offline to online. Reconnect is a transition, not a polling
loop; work that needs a retry should also be safe to call manually.

## Probe the server

Set the optional `probe_url` prompt and install an `HttpClient`. The extension
can then send a lightweight `HEAD` request:

```dart
if (gate.has<NetworkMonitor>()) {
  final reachable = await gate.networkReachable();
  reachable.fold(
    ok: (value) => setServerReachable(value),
    err: (failure) => setServerReachable(false),
  );
}
```

`networkReachable` comes from `gate_connectivity.dart`; import that file. It
returns `Ok(false)` for an unreachable/failed probe and can be called on app
resume or on your own schedule. Without a probe URL, status follows platform
connectivity only.

## Offline guard

When `http_pipeline` is installed, `OfflineGuardMiddleware` is added at
priority 5. It fails fast with `networkOffline` while the device is offline,
before retry/cache/auth middleware run. This is intentional: don't send a
request that cannot leave the device.

## Testing

Use `FakeConnectivity` to set status and emit changes. For the probe, provide a
`FakeHttpClient` that returns a 200/error/timeout; the support probe itself must
not prompt or block startup.
