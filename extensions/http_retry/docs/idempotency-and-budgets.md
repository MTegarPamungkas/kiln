# Idempotency and budgets

Retries are safe only when replaying the request cannot duplicate a side effect.
The middleware decides that before it decides whether the status is retryable.

## Which requests may be replayed

| Method | Replayed? |
| --- | --- |
| `GET`, `HEAD`, `PUT`, `DELETE` | Yes, by method semantics |
| `POST`, `PATCH` | Only when an `Idempotency-Key` header is present |

The check is case-insensitive. An `Idempotency-Key` value is sent unchanged to
the server; the backend must enforce it and return the same result for a replay.

```dart
await gate.httpPost(
  uri,
  body: order.toJson(),
  headers: {'Idempotency-Key': order.id},
);
```

## Status codes

The default retryable set is `408`, `429`, `500`, `502`, `503`, `504`.
For a retryable response, `Retry-After` (seconds or HTTP date) takes precedence
over exponential backoff. A `Failure` is retried only when it is marked
`isRetryable`; its delay uses backoff, because no HTTP response exists to carry
`Retry-After`. Validation, authentication after refresh, and cancellation are
not retried.

## Attempts and budget

- `maxAttempts` counts the first request plus retries. With the default `3`, a
  request is sent at most three times.
- The budget defaults to 10 retries per path per rolling minute. A path that
  exhausts it is returned to the caller without another retry.
- Backoff starts at `initialDelay` (250 ms), doubles, caps at `maxDelay` (8 s),
  and applies 0.8–1.2 jitter when enabled.
- The retry attempt number starts at 1; the first delay uses the initial delay.

## Observing and tuning

```dart
registry.registerSingleton<RetryEvents>(
  RetryEvents(
    onRetry: (event) => logger.debug(
      'retry ${event.attempt} in ${event.delay} (${event.reason.name})',
    ),
    onGiveUp: (event) => logger.warning(
      'gave up after ${event.attempt}: ${event.failure?.code}',
    ),
  ),
);
```

`RetryEvents` must be registered before bootstrap. Tune prompts through
`kiln add http_retry` or edit `retry_settings.dart`; keep `maxDelay >=
initialDelay`.

## Pitfalls

- Do not add `Idempotency-Key` with a new random value per attempt; use the
  stable operation id.
- A retry inside the middleware is not a new application operation; do not
  enqueue another job for it.
- Cancellation must not be retried. The middleware sees the `cancelled` failure
  and stops.
- The budget is a safety net, not a rate limiter for the whole API; use a
  dedicated rate limiter for that.
