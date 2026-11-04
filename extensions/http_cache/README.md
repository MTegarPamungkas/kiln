# http_cache

HTTP response cache middleware for `HttpPipeline`.

- In-memory cache by default; uses `Storage` when the storage extension
  is installed.
- Honors `Cache-Control: max-age`, `no-store`, `no-cache`, and
  `stale-while-revalidate`.
- Supports `ETag`/`If-None-Match` and 304 responses.
- Invalidates entries after a mutation request.
- Cache key includes method, URL, query, and common `Vary` headers.
- Entry count limit with eviction of the oldest entries.

```bash
kiln add http_cache
```

## Gate

Caching runs as `HttpPipeline` middleware automatically; there are no
request/response verbs to call.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
