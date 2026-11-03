# Connectivity

```dart
final monitor = RegistryScope.read<NetworkMonitor>(context);
final status = monitor.status;
```

Status awal `unknown` sampai platform memberi jawaban. `OfflineBanner` tidak
tampil selama status masih unknown agar tidak berkedip saat start.

`OfflineGuardMiddleware` dipasang ke `http.interceptors` dengan priority 5 bila
`http_pipeline` tersedia.
