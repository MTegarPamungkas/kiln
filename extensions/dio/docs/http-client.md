# HTTP client

`DioClient` implements the `HttpClient` contract from `kiln_core`. It sends
every request through `HttpPipeline`, so middleware such as retry, cache, and
logging can be added without changing application code.

```dart
final client = RegistryScope.read<HttpClient>(context);
final response = await client.post(
  Uri.parse('/auth/login'),
  body: {'email': email, 'password': password},
);
```

Failures are always `Failure`. Access denied, timeouts, offline devices, and
server errors carry stable `FailureCode` values.

## Gate

Requests are also available as one-call `Result` verbs:

```dart
final result = await gate.httpPost(
  Uri.parse('/auth/login'),
  body: {'email': email, 'password': password},
);

final session = result.fold(
  ok: (response) => response.data,
  err: (failure) => throw StateError(failure.message),
);
```
