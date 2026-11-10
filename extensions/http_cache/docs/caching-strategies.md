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

Authenticated requests already bypass the cache, so a shared cache cannot leak
one account's response to another. Backends should still send
`Cache-Control: private, no-store` on sensitive endpoints as defence-in-depth.
For the full safety rules, see
[security and revalidation](security-and-revalidation.md).
