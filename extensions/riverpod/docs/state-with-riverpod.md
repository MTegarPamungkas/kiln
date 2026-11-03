# State with Riverpod

`registryProvider` is populated by the app wrapper. Features read contracts
through `kilnProvider<T>()`:

```dart
final profileProvider = FutureProvider<Profile>((ref) async {
  final client = ref.watch(kilnProvider<HttpClient>());
  final response = await client.get(Uri.parse('/profile'));
  return Profile.fromJson(response.data);
});
```

Use the `ProviderScope` from the app wrapper; tests can use
`registryOverrides` to install a fake Registry.
