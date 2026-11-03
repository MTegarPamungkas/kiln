# Offline-first pattern

1. Read from `LocalDatabase` first.
2. Show the `NetworkMonitor` status.
3. When online, send changes from the `SyncQueue` to `RemoteDatabase`.
4. Apply the server result back to the local store.
5. Use `watch` to update the UI without polling.

Make sure conflicts have a clear rule: last-write-wins, server version, or
manual resolution.
