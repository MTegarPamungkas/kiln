# Changelog

## 0.2.0

- Expose `cache`, `invalidateCache`, and `clearCache` on the `Gate` facade so
  the application can purge cached responses programmatically.
- Fix tag-based invalidation in `StorageHttpCache` to match the stored tags
  instead of scanning the raw JSON payload.

## 0.1.1

- Validate cache TTL, entry count, and status codes.
- Report the memory/storage backend and settings through `SupportRegistry`.

## 0.1.0

- Initial HTTP cache with TTL, ETag, stale-while-revalidate, invalidation, and
  memory/storage stores.
