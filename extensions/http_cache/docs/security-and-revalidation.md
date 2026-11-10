# Security and revalidation

The HTTP cache is conservative by default because a wrong cache hit is a data
leak, not a performance bug.

## Authenticated requests bypass the cache

Requests carrying `Authorization`, `Cookie`, or `Proxy-Authorization` are never
served from the shared cache and their responses are never stored. This prevents
one account's response from being returned to another account. If an app needs a
per-user cache, implement it behind an identity-scoped key at the application
layer; the bundled middleware deliberately does not guess an identity.

## What is never stored

A response is not cached when it has:

- `Cache-Control: no-store`
- `Cache-Control: private` (including `private="..."`)
- `Set-Cookie`, `WWW-Authenticate`, or `Proxy-Authenticate`
- `Vary: *`
- a `Vary` header naming a header that is not part of the cache key

The default key covers method, resolved URL, and the `accept` and
`accept-encoding` headers. Supply a `CacheKeyBuilder` with additional
`varyHeaders` when a backend varies on tenant, language, or another header; a
`Vary` header that is not keyed makes the response uncacheable.

## Freshness and revalidation

- `max-age` drives freshness. Without it, `defaultTtl` applies.
- `no-cache` stores the response but forces revalidation on the next request.
- `must-revalidate` forbids serving stale data.
- `ETag`/`If-None-Match` are used when an entry is stale. A `304` reuses the
  stored body and merges updated headers; a `304` that becomes `private`,
  `no-store`, or otherwise uncacheable removes the entry.
- `stale-while-revalidate` may serve the old body while a refresh runs, but only
  when the response explicitly allows it.
- `stale-if-error` is the only path that serves stale data after a transport
  failure. It requires an explicit window and a transient network failure
  (timeout, offline, unreachable); authentication failures, cancellation,
  validation errors, and programmer errors are never hidden by cache fallback.

## Mutations

A mutation (`POST`, `PUT`, `PATCH`, `DELETE`) passes through to the transport. On
a successful response, entries whose URL path starts with the mutation path are
invalidated and the mutation response is not cached. A mutation that throws does
not invalidate; the server may not have applied it.

## Backend and eviction

The default backend is in-memory. When `storage` is installed, entries are
persisted through `Storage` under a namespace. The cache keeps at most
`maxEntries` responses and evicts the oldest `storedAt` entry when full.

## Checklist

- Keep private data on authenticated requests, which bypass this cache.
- Set `Cache-Control: private, no-store` on sensitive endpoints as
  defence-in-depth.
- Add every varied header to the key builder; otherwise those responses are not
  cached.
- Do not use cache fallback as an auth-retry mechanism.
- Test account switching, logout, token expiry, and mutation invalidation against
  the real pipeline, not a fake that skips middleware.

The regression suite for this behavior lives in
`test/extensions/http_cache/cache_interceptor_test.dart`.
