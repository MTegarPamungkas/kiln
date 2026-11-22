# Changelog

## 0.1.1

- Invalidate collection caches after row mutations and serialize cache writes
  with invalidation so a delayed store cannot restore an older snapshot.

- Authenticated requests bypass the shared cache, and private or session
  responses are never stored.
- Response `Vary` headers must be part of the cache key; `no-cache`,
  `must-revalidate`, and cancellation are honored.
- Range requests and `206`/`Content-Range` responses bypass the cache; stale
  refreshes are deduplicated and fenced by mutation revisions, and cache
  failures are best effort. The storage cache evicts the oldest `storedAt`.
- Stale data is served only inside an explicit `stale-if-error` window after a
  transient network failure.

## 0.1.0

- Initial release.
