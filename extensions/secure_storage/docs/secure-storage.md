# Secure storage

```dart
final vault = RegistryScope.read<SecureStorage>(context);
await vault.write('token', token);
final token = await vault.read('token');
```

`SecureTokenStore` wraps `SecureStorage` and satisfies `TokenProvider`.
`NamespacedSecureStorage` separates keys per extension. Do not put server keys in
the client app.
