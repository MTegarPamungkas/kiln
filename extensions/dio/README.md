# dio

HTTP client for Kiln built on `dio`.

The extension provides the `http_client` and `http_pipeline` capabilities and
opens the `http.interceptors` slot. Other extensions contribute
`HttpMiddleware` instead of importing dio.

```bash
kiln add dio --answer base_url=https://api.example.com
```

Application code reads the contract, never the implementation:

```dart
final client = RegistryScope.read<HttpClient>(context);
final response = await client.get(Uri.parse('/users'));
```

Relative paths are resolved against the configured `base_url`.

## API key

Configure where the key goes, then pass the key at build time:

```bash
kiln add dio \
  --answer base_url=https://api.example.com \
  --answer api_key_header=X-Api-Key
flutter run --dart-define=KILN_API_KEY=secret
```

Use `api_key_query=key` instead of a header when the API expects the key in the
query string. `api_key_prefix` supports values such as `Bearer `.

## Gate

```dart
final users = await gate.httpGet(Uri.parse('/users'));   // Result<HttpResponse>
final created = await gate.httpPost(uri, body: {'name': 'Ana'}); // Result<HttpResponse>

users.fold(
  ok: (response) => print(response.statusCode),
  err: (failure) => print(failure.code),
);
```

Every request returns a `Result` instead of throwing a `Failure`.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
