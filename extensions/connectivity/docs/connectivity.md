# Connectivity

```dart
final monitor = RegistryScope.read<NetworkMonitor>(context);
final status = monitor.status;
```

The initial status is `unknown` until the platform gives an answer. Read
`monitor.status` or `monitor.statusListenable` in an application-owned banner
and ignore `unknown` if you do not want a flicker at startup.

`OfflineGuardMiddleware` is installed into `http.interceptors` with priority 5
when `http_pipeline` is available.
