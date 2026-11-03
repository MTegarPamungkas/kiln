# Connectivity

```dart
final monitor = RegistryScope.read<NetworkMonitor>(context);
final status = monitor.status;
```

The initial status is `unknown` until the platform gives an answer.
`OfflineBanner` is not shown while the status is still unknown so it does not
flicker at startup.

`OfflineGuardMiddleware` is installed into `http.interceptors` with priority 5
when `http_pipeline` is available.
