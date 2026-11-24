# Retry policy

Defaults:

- At most 3 attempts.
- Initial delay 250 ms, cap 8 seconds, jitter enabled.
- Retried statuses: 408, 429, 500, 502, 503, 504.
- GET, HEAD, OPTIONS, PUT, and DELETE are considered idempotent.
- POST/PATCH are only retried when the `Idempotency-Key` header is present.
- Default budget of 10 retries per minute per path.
- No total time budget by default; set `totalBudget` to cap one request's whole
  retry sequence in wall-clock time.
- A request-level `HttpRequest.deadline` is honoured too; the stricter of the two
  bounds wins and an expired deadline fails with
  `network.deadline_exceeded`.

`Retry-After` takes precedence over backoff. When the budget runs out, the
response/failure is returned without a retry. A wait is clipped to the remaining
total budget, and no new attempt starts once it is spent.

Configure it through the prompt during `kiln add http_retry` or by editing
`lib/extensions/http_retry/retry_settings.dart`. An application can pass its own
settings to the module:

```dart
HttpRetryModule(
  settings: HttpRetrySettings.defaults.copyWith(
    totalBudget: const Duration(seconds: 20),
  ),
)
```

## Observing retries

The middleware reports `onRetry` and `onGiveUp` when the application registers a
`RetryEvents` singleton before bootstrap. `HttpRetryModule` reads it with
`readOrNull` and passes it to the middleware, so no application code has to
rebuild the pipeline.
