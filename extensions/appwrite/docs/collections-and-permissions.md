# Collections, permissions, and queries

Appwrite 1.8 renamed *collection* and *document* to *table* and *row*. This
extension uses the TablesDB API, but the contract argument name stays
`collection` so application code does not depend on backend terminology. The
`collection` value is the Appwrite table id.

## Document shape

`RemoteDatabase` returns the stored columns plus `id` containing the Appwrite row
id. System columns such as `$createdAt` are not copied; add an ordinary column if
the application needs them.

```dart
final created = await database.create('tasks', {
  'title': 'Send report',
  'done': false,
});
final id = created['id'];
```

## Supported RemoteQuery

| RemoteQuery | Appwrite query |
| --- | --- |
| `equals` | `equal`, or `isNull` when the value is null |
| `notEquals` | `notEqual`, or `isNotNull` when the value is null |
| `greaterThan` | `greaterThan` |
| `greaterThanOrEqual` | `greaterThanEqual` |
| `lessThan` | `lessThan` |
| `lessThanOrEqual` | `lessThanEqual` |
| `inList` | `equal` with a list of values |
| `notInList` | `notEqual` with a list of values |
| `arrayContains` | `containsAny` with a single value |
| `isNull` | `isNull` |
| `isNotNull` | `isNotNull` |
| `RemoteOrder` ascending | `orderAsc` |
| `RemoteOrder` descending | `orderDesc` |
| `limit` | `limit` |
| `offset` | `offset`, only when greater than zero |

Values that cannot be translated, for example `inList` without a list, are
thrown as `Failure(validation.invalid_input)` before the request is sent.

## Permissions

Permissions in Appwrite attach to rows and buckets, not just to tables. Common
patterns:

- **User-owned data.** Create rows with `read("user:$userId")` and
  `update("user:$userId")` permissions, then filter with
  `RemoteFilter('userId', ...)` as an extra layer.
- **Public data.** Grant `read("any")` and restrict write operations to specific
  roles.
- **Files.** Private buckets require a user session. `FileStorage.url` uses the
  Appwrite `view` endpoint so the session cookie is sent along from the
  application.

The row `id` is always filled in by the extension; do not use a column named
`id` for application data because its value will be overwritten.
