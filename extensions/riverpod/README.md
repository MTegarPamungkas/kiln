# riverpod

State management Kiln berbasis `flutter_riverpod`.

Extension ini exclusive di kategori `state`, menyediakan `state_riverpod`, dan
menambahkan `ProviderScope` lewat slot `app.wrappers`. Registry di-override ke
provider, sehingga fitur dapat membaca kontrak dengan:

```dart
final client = ref.watch(kilnProvider<HttpClient>());
```

Isi brick:

- `kiln_providers.dart` — `registryProvider` dan `kilnProvider<T>()`.
- `provider_overrides.dart` — override Registry untuk test.
- `async_value_x.dart` — akses failure/data yang ringkas.
- `session_notifier.dart` — membungkus `SessionController`.
- contoh fitur counter.
