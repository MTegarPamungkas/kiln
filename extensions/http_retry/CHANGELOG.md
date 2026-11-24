# Changelog

## 0.1.2

- Key `RetryMiddleware` retry budget consumption by host instead of dynamic
  request path so retry storms against a failing backend are bounded.
- Prune expired keys from `RetryBudget` so the bucket map does not grow
  unboundedly.

## 0.1.1

- Repack archive with deterministic cross-OS gzip and without root `test/`.

## 0.1.0

- `HttpRequest.deadline` is honoured with `totalBudget`: the stricter bound wins,
  waits are clipped to it, and an expired deadline throws
  `network.deadline_exceeded`.
- `HttpRetrySettings.totalBudget` caps one request's whole retry sequence in
  wall-clock time: waits are clipped to the remaining budget and no attempt
  starts once it is spent. `copyWith` and the module's optional `settings` make
  it configurable; it stays off by default.

- Cancellation interrupts retry waits immediately and cancels owned timers;
  cancelled requests cannot trigger another retry attempt.

- Initial release.
