# Composed Dio + HTTP cache against a loopback server

Date: 2026-11-21 (Asia/Jakarta). Closes the "required fixture 1" note for K30/K31
in [findings](findings.md).

## Why a separate fixture

`dio` provides the transport and pipeline; `http_cache` contributes middleware to
it. Each extension's rendered suite can only install one extension, and `dio`
must not depend on `http_cache` (the capability direction is the other way), so
the composition could not be covered by either suite. Both suites also mostly use
fakes for the transport.

`tool/e2e/dio_cache_probe.dart` renders both bricks into
`.dart_tool/dio_cache_probe`, writes
`tool/e2e/dio_cache_composition_test.dart.template` into it as
`test/composition_test.dart`, then runs `flutter pub get` and `flutter test`. The
test builds a real `DioClient`, a real `HttpPipeline` with the real
`CacheInterceptor` and `MemoryHttpCache`, and a real loopback `HttpServer`; a
per-method/path hit counter proves whether the server was reached.

```
dart run tool/e2e/dio_cache_probe.dart
```

## Scenarios and results

| Scenario | Assertion |
| --- | --- |
| Repeat GET with `max-age=60` | Second response has `fromCache: true`, server hit once, same body. |
| `Cache-Control: no-store` | Both responses are network responses, two server hits. |
| POST after a cached GET | The mutation invalidates the collection: the next GET reaches the server (`GET /items` twice, `POST /items` once). |
| `Range` request while a full response is cached | The range request bypasses the cache (206, `fromCache: false`) and does not replace the full entry; the following full GET is still `fromCache: true`. |
| Stale entry with an ETag, `staleWhileRevalidate` off | The revalidation sends `If-None-Match`, the server answers 304, the client returns the cached body with `fromCache: true` (two server hits). |

All five pass on a real loopback server:

```
00:00 +5: All tests passed!
```

## Limits

- The server is plain HTTP on loopback; TLS, proxies, HTTP/2 and browser
  behaviour are not covered here.
- `staleWhileRevalidate` is disabled in this fixture so revalidation is
  deterministic; the stale-serving path stays covered by the extension's own
  tests.
- Range-aware caching is still deliberately deferred: a 206 must never occupy the
  full-response key, which is what this fixture asserts.
- The fixture is manual, like the Appwrite probe: it is not part of `flutter test`
  in the repository, because it renders and resolves a project first.
