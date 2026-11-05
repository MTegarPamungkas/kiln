# Key-value storage

Store small app values — feature flags, cached ids, "seen" markers — through the
`Storage` contract, backed by SharedPreferences:

```dart
final storage = RegistryScope.read<Storage>(context);
await storage.write('onboarding_done', 'true');
final done = await storage.read('onboarding_done');
```

Use `StorageKey<T>` for typed values and `JsonCodec` for objects.
`NamespacedStorage` separates extension-owned keys from app keys.
