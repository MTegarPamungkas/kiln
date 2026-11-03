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
