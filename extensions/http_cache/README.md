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
