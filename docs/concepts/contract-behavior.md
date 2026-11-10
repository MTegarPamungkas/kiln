# Contract behavior

Contracts in `kiln_core` define behavior, not just method names. Every provider
must produce the same observable outcome for the same input, so application code
can swap a backend without changing feature code.

This page is the written specification. The executable version lives in
`kiln_testing` contract suites; a provider that disagrees with this page fails
its contract test.

## The outcome rules

- Contracts throw `Failure`; they never return a boolean that means "failed".
- `Result` and `Gate` convert a thrown `Failure` into `Err`. A missing contract
  through `Gate` is `Err` with `configuration.missing`, not an exception.
- Empty results are data, not errors: a query with no matches returns an empty
  list, and a missing single record is `null` where the signature allows it.
- Provider-specific exceptions, status codes, and messages never cross the
  contract boundary. They become a stable `FailureCode`.
- Contracts do not render UI, show dialogs, or prompt for permission. They
  return data or a failure; the application decides what the user sees.

## Missing records

| Operation | Missing record |
| --- | --- |
| `RemoteDatabase.read(collection, id)` | Returns `null` |
| `RemoteDatabase.update(collection, id, data)` | Throws `Failure(remote_database.not_found, database)` |
| `RemoteDatabase.delete(collection, id)` | Throws `Failure(remote_database.not_found, database)` |
| `RemoteDatabase.query(collection, query: ...)` | Returns an empty list |
| `RemoteDatabase.watch(collection, id)` | Emits the current snapshot, then changes; `null` means the row is absent or deleted |
| `FileStorage.download(path)` for an absent object | Throws `Failure(file.not_found, storage)` |

Object deletion is not an existence probe. The neutral contract only guarantees
that `download` reports a missing object; deleting an already-absent object is
provider-defined. Callers must not use `delete` to test whether an object
exists, and the SDK does not add an extra existence round-trip.

`watch` is a snapshot stream: the first event is the current row (or `null`),
later events are updates, and an event is `null` after deletion. Cancelling the
subscription closes the underlying backend subscription. Stream errors are
mapped to `Failure` like method calls.

## Pagination

There are two levels:

- `RemoteDatabase.query` returns one list. A provider must honor `limit` and
  `offset` when it supports them; `offset` defaults to `0`. A `limit` of `null`
  means "no explicit limit from the caller" and the provider may apply its own
  maximum.
- `PaginatedRemoteDatabase.queryPage` is the optional explicit page API. It
  returns a `RemotePage` and must set `nextOffset` when more rows exist, or
  `nextCursor` when the backend uses cursor pagination. `totalCount` is set only
  when the backend knows it. `hasMore` is true when either continuation is
  non-null.
- `RemoteQuery.cursor` is opaque. Pass back exactly the `nextCursor` from the
  previous page; do not parse it. When a provider supports cursors, prefer them
  over offsets because they stay stable while rows are inserted or removed.

No bundled connector currently advertises `PaginatedRemoteDatabase`; the
portable path today is `query` with `limit`/`offset`. The interface and its
contract suite define how a provider opts in later. Callers feature-detect the
capability instead of assuming it:

```dart
final database = registry.read<RemoteDatabase>();
final paged = database is PaginatedRemoteDatabase ? database : null;
```

## Combining filters

`RemoteQuery.filters` is a conjunction: every entry must match. There is no
implicit OR.

- Multiple filters on the same field are all preserved. `score >= 10` and
  `score < 20` in one query is a range, not "last one wins".
- `inList` and `notInList` take an iterable value. Invalid list values are a
  validation failure (`validation.invalid_input` or
  `validation.unsupported_value`), not an empty result.
- Use `isNull` and `isNotNull` for null checks; null is not a comparable list
  element.
- `orderBy` is applied before `offset` and `limit`.
- Grouping (`OR`, nested groups) is not part of the neutral contract. An app
  that needs it should use a backend-specific API and accept that it is no
  longer portable.

The backend-neutral rule is deliberately conservative: a filter either matches
the same rows on every provider or fails before a request is sent.

## Logout failures

`AuthRepository.signOut` means "the local session is gone", even when the
backend cannot be reached.

- The provider must clear its local session, tokens, and cached user data.
- `currentSession` becomes `null` and `authStateChanges` emits `null`.
- Remote token revocation is best-effort. A network error, timeout, or server
  error during revocation must not leave the app signed in.
- If local cleanup itself fails, throw a `Failure` (for example
  `unavailable`, `authentication`). Do not report success while credentials
  remain on the device.
- A failed logout is never converted into a UI action by the SDK. The app reads
  the `Result` and decides whether to retry, show a message, or continue.

## Unsupported backends and devices

Support has three separate layers; see
[../extensions/support-and-devices.md](../extensions/support-and-devices.md).

1. **Manifest/platform**: a module filtered out by `platforms` is not
   registered. Its contracts are absent.
2. **Runtime support**: `KilnModule.support()` records a `SupportInfo` in
   `SupportRegistry`. The contract stays registered so calls return a typed
   failure instead of a missing-service error.
3. **Call outcome**: a call that cannot run throws
   `SupportInfo.toFailure()`, which maps to
   `support.unsupported_platform`, `support.unsupported_device`,
   `configuration.missing`, `permission.denied`, or `unavailable`.

Application code probes optional capabilities through the Gate:

```dart
if (!gate.has<Biometric>()) {
  // The extension is not installed or not registered on this platform.
}
final support = gate.support['biometric'];
if (support != null && !support.isSupported) {
  // Show support.message and choose a fallback.
}
```

An unsupported backend is therefore never a silent crash or a fabricated success.
It is either an absent contract (`Gate` returns `Err(configuration.missing)`) or
a typed support failure from the call.

## Executable specification

`kiln_testing` ships the contract suites:

- `remoteDatabaseContract` — CRUD, filters/order/limit, watch, missing records.
- `paginatedRemoteDatabaseContract` — page continuation and empty pages for
  providers that opt into `PaginatedRemoteDatabase`.
- `batchRemoteDatabaseContract` — batch writes and helpers for providers that
  opt into `BatchRemoteDatabase`.
- `fileStorageContract` — upload/download/url/delete and progress.
- `authRepositoryContract` — session lifecycle and sign-out.
- `accountManagementContract`, `socialAuthContract`, and the storage,
  connectivity, logger, and notifications suites.

Extension tests call these suites against their fake or in-memory adapter, and
the rendered connector tests call the same behavior through the real adapter
where possible. When a contract changes, change this page and the suite
together.
