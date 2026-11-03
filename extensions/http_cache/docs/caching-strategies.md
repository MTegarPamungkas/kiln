# Caching strategies

Defaults:

- Only GET/HEAD responses are cached.
- TTL comes from `Cache-Control: max-age`, otherwise the default is 60 seconds.
- Responses with `Cache-Control: no-store` are not stored.
- `no-cache` stores the entry but does not treat it as fresh.
- `stale-while-revalidate` returns the old entry and then refreshes in the
  background.
- Mutation requests invalidate entries with the same path prefix.
- At most 100 entries; the oldest entries are evicted first.

For personal data, the backend should send `Cache-Control: private, no-store`
or the app should avoid caching those endpoints.
