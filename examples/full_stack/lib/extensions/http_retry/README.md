# http_retry

Retry middleware for `HttpPipeline`.

This extension requires `http_client` and `http_pipeline` (provided by `dio`)
and attaches to the `http.interceptors` slot with priority 20.

Features:

- retry only for idempotent methods or requests with an `Idempotency-Key`,
- status 408, 429, 500, 502, 503, 504,
- exponential backoff with jitter,
- `Retry-After` in seconds or as an HTTP date,
- retry budget per time window,
- retry/give-up event callbacks.

```bash
kiln add http_retry
```

## Gate

Retry runs as `HttpPipeline` middleware automatically; there are no
request/response verbs to call. Register a `RetryEvents` before bootstrap to
observe retries and give-ups:

```dart
registry.registerSingleton<RetryEvents>(
  RetryEvents(
    onRetry: (event) => logger.debug('retry #${event.attempt}'),
    onGiveUp: (event) => logger.warning('gave up after #${event.attempt}'),
  ),
);
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
