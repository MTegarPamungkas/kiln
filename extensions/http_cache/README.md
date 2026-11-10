# http_cache

HTTP response cache middleware for `HttpPipeline`.

- In-memory cache by default; uses `Storage` when the storage extension
  is installed.
- Honors `Cache-Control: max-age`, `no-store`, `no-cache`, `private`,
  `must-revalidate`, `stale-while-revalidate`, and `stale-if-error`.
- Bypasses authenticated requests; never stores `Set-Cookie` or `private`
  responses.
- Supports `ETag`/`If-None-Match` and 304 responses.
- Invalidates entries after a successful mutation request.
- Cache key includes method, resolved URL, query, and configured `Vary` headers;
  unkeyed `Vary` responses are not cached.
- Entry count limit with eviction of the oldest entries.

See [security and revalidation](docs/security-and-revalidation.md) for the exact
cache-safety rules and [caching strategies](docs/caching-strategies.md) for
tuning.

```bash
kiln add http_cache
```

## Gate

Caching runs as `HttpPipeline` middleware automatically; there are no
request/response verbs to call. Cache management is exposed through the facade:

```dart
await gate.invalidateCache('/users');            // Result<void>
await gate.invalidateCache('/users', tag: 'users'); // Result<void>
await gate.clearCache();                         // Result<void>
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
