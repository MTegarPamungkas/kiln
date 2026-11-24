# Changelog

## 0.1.3

- Add in-memory LRU and tag index plus byte budget (`maxBytes`) to
  `StorageHttpCache` so eviction and invalidation no longer decode every stored
  entry on the UI isolate.
- Upgrade `MemoryHttpCache` to true LRU eviction, byte budget enforcement, tag
  indexing, and defensive cloning of cached responses.
- Fix `CacheInvalidation` to skip `/api` and `/vN` prefix segments when deriving
  tags and to match prefixes by path-segment boundaries (`/users/4` no longer
  invalidates `/users/42`).
- Serialize writes per cache key instead of globally and coalesce concurrent
  identical in-flight GET requests.

## 0.1.2

- Repack archive with deterministic cross-OS gzip and without root `test/`.

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
