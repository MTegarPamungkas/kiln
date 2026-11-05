# Offline-first pattern

The default read path is local; the network is a background synchronizer. This
keeps the UI instant and usable with no connection.

1. **Read local first.** Serve the screen from `LocalDatabase` immediately.
2. **Show connectivity.** Reflect `NetworkMonitor` status so the user knows
   whether changes can sync.
3. **Queue writes.** On a mutation, write locally and enqueue the change in the
   `SyncQueue`; do not wait for the network.
4. **Flush when online.** When the network is back, send queued items to
   `RemoteDatabase` and apply the server result back into the local store.
5. **Observe, don't poll.** Use `LocalDatabase.watch` so the UI updates when the
   sync result lands.

Decide a conflict rule up front — last-write-wins, server-version-wins, or manual
merge — and apply it in the flush step so a failed sync never silently drops data.
