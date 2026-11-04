# Retry policy

Defaults:

- At most 3 attempts.
- Initial delay 250 ms, cap 8 seconds, jitter enabled.
- Retried statuses: 408, 429, 500, 502, 503, 504.
- GET, HEAD, OPTIONS, PUT, and DELETE are considered idempotent.
- POST/PATCH are only retried when the `Idempotency-Key` header is present.
- Default budget of 10 retries per minute per path.

`Retry-After` takes precedence over backoff. When the budget runs out, the
response/failure is returned without a retry.

Configure it through the prompt during `kiln add http_retry` or by editing
`lib/extensions/http_retry/retry_settings.dart`.

## Observing retries

The middleware reports `onRetry` and `onGiveUp` when the application registers a
`RetryEvents` singleton before bootstrap. `HttpRetryModule` reads it with
`readOrNull` and passes it to the middleware, so no application code has to
rebuild the pipeline.
