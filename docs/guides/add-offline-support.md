# Adding offline support

Planned combination:

- `connectivity` — monitors the network and provides the `offline_guard`
  middleware.
- `http_cache` — serves fresh responses from the cache.
- `local_db` — stores local documents and the sync queue.

## Pattern

1. Read from `LocalDatabase` first.
2. Show status from `NetworkMonitor`.
3. When online, sync the `sync_queue` to `RemoteDatabase`.
4. Use `http.interceptors` for the offline guard, retries, and caching.
5. Write tests with the `NetworkMonitor`, `HttpClient`, and `LocalDatabase`
   fakes from `kiln_testing`.

`storage`, `http_cache`, and `local_db` are already available in the catalog.
`connectivity` follows in the platform group; see [roadmap](../roadmap.md).
