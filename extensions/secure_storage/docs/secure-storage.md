# Secure storage

```dart
final vault = RegistryScope.read<SecureStorage>(context);
await vault.write('token', token);
final token = await vault.read('token');
```

`SecureTokenStore` membungkus `SecureStorage` dan memenuhi `TokenProvider`.
`NamespacedSecureStorage` memisahkan key per extension. Jangan menaruh kunci
server di aplikasi klien.
