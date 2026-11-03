# Key-value storage

```dart
final storage = RegistryScope.read<Storage>(context);
await storage.write('onboarding_done', 'true');
final done = await storage.read('onboarding_done');
```

Gunakan `StorageKey<T>` untuk nilai bertipe dan `JsonCodec` untuk objek.
`NamespacedStorage` memisahkan key milik extension dari key aplikasi.
