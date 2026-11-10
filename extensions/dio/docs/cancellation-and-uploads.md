# Cancellation and uploads

The contract covers JSON requests. Dio-specific helpers cover streaming uploads
and downloads; they still map every failure to `Failure`.

## Cancel when a screen closes

```dart
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with HttpCancelTokenOwner<SearchPage> {
  final client = ...; // RegistryScope.read<HttpClient>(context)

  Future<void> search(String term) async {
    final result = await gate.httpGet(
      Uri.parse('/search'),
      queryParameters: {'q': term},
      cancelToken: httpCancelToken,
    );
    if (!mounted) return;
    result.fold(ok: render, err: handle);
  }
}
```

`HttpCancelTokenOwner` cancels on dispose. You can also cancel manually with
`token.cancel()`. A cancelled request becomes `Failure(cancelled)`; the transport
stops before reading the response. Do not show an error dialog for
`failure.isCancelled`.

## Multipart upload

```dart
final client = registry.read<HttpClient>() as DioClient;
final response = await uploadMultipart(
  client,
  path: '/avatars',
  field: 'file',
  filename: 'avatar.png',
  bytes: pngBytes,
  fields: {'userId': 'u1'},
  headers: {'Accept': 'application/json'},
  onProgress: (progress) => setProgress(progress),
);
```

`uploadMultipart` sends `multipart/form-data`, reports `onSendProgress` as
0..1, and maps `DioException` through the same failure mapper as the normal
client. Use `FileStorage.upload` instead when the backend is a storage provider
rather than a JSON API.

## Download to a file

```dart
await downloadFile(
  client,
  path: '/exports/report.pdf',
  savePath: localPath,
  onProgress: (progress) => setProgress(progress),
);
```

`downloadFile` writes to `savePath`, reports `onReceiveProgress`, and throws a
`Failure` on transport/status errors. For bytes in memory, use
`gate.downloadFile`/`FileStorage.download` instead.

## API key

The API key is read at build time:

```bash
kiln add dio --answer base_url=https://api.example.com \
  --answer api_key_header=X-Api-Key
flutter run --dart-define=KILN_API_KEY=secret
```

The extension adds the key to the configured header, or to the query parameter
when `api_key_query` is set. `api_key_prefix` supports values like `Bearer `.
The key is not stored in `kiln.yaml`; keep it out of source control.

## Timeouts and relative URLs

`connect_timeout` controls the connection timeout. Relative paths are resolved
against `base_url`. The API key is scoped to the `base_url` scheme, host, and
port; a request to a third-party origin never receives it. This mirrors the
REST auth origin guard.
