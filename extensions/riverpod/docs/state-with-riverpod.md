# State dengan Riverpod

`registryProvider` diisi oleh wrapper aplikasi. Fitur membaca kontrak lewat
`kilnProvider<T>()`:

```dart
final profileProvider = FutureProvider<Profile>((ref) async {
  final client = ref.watch(kilnProvider<HttpClient>());
  final response = await client.get(Uri.parse('/profile'));
  return Profile.fromJson(response.data);
});
```

Gunakan `ProviderScope` dari wrapper aplikasi; test dapat memakai
`registryOverrides` untuk memasang fake Registry.
