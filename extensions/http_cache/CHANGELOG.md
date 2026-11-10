# Changelog

## 0.1.1

- Authenticated requests bypass the shared cache, and private or session
  responses are never stored.
- Response `Vary` headers must be part of the cache key; `no-cache`,
  `must-revalidate`, and cancellation are honored.
- Stale data is served only inside an explicit `stale-if-error` window after a
  transient network failure.

## 0.1.0

- Initial release.
