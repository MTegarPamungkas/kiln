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

## Deadlines

`HttpRequest.deadline` bounds the whole exchange. `DioClient` rejects an already
expired request before touching the transport, clamps connect/send/receive
timeouts to the remaining time, and cancels the Dio call when the deadline
passes. The result is `Failure(network.deadline_exceeded)`. A request without a
deadline keeps the configured timeouts. Cancellation via `HttpCancelToken` keeps
working independently; a deadline never turns a successful in-flight response
into a failure retroactively.

```dart
await client.send(
  HttpRequest(
    method: HttpMethod.get,
    uri: Uri.parse('/users'),
    deadline: DateTime.now().add(const Duration(seconds: 5)),
  ),
);
```


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
