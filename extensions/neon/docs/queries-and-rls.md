# Queries and row-level security

The Neon connector maps `RemoteQuery` to PostgREST query parameters. The same
contract works against Supabase, Appwrite, Firebase, or a fake; this page covers
the Neon-specific behavior and the authorization you must add in Postgres.

## Filters

Every filter is ANDed. Repeated filters on one column are preserved, so a range
is one query:

```dart
final result = await gate.remoteQuery(
  'orders',
  query: const RemoteQuery(
    filters: [
      RemoteFilter('total', RemoteFilterOperator.greaterThanOrEqual, 10),
      RemoteFilter('total', RemoteFilterOperator.lessThan, 20),
      RemoteFilter('status', RemoteFilterOperator.inList, ['paid', 'shipped']),
      RemoteFilter('deleted_at', RemoteFilterOperator.isNull),
    ],
    orderBy: [RemoteOrder('created_at', direction: RemoteSortDirection.descending)],
    limit: 50,
    offset: 0,
  ),
);
```

- `inList`/`notInList` values are quoted for PostgREST; numbers and booleans stay
  bare.
- Null uses `isNull`/`isNotNull`; null is not a valid list element.
- Grouping (`OR`, nested groups) is not part of the neutral contract. Use a
  Postgres view or RPC if you need it.
- `orderBy` is applied before `offset`/`limit`.

Filters are serialized as HTTP query parameters by `HttpNeonGateway`; tests
should inspect the generated URL rather than only evaluating a fake store.

## Pagination

The portable path is `limit` + `offset`. Neon does not advertise
`PaginatedRemoteDatabase`, so `queryPage` is not available; use offset paging and
treat an empty page as the end. `RemoteQuery.cursor` is ignored by this connector.

## Roles and JWTs

The Data API uses a Neon Auth JWT:

- Signed out → anonymous JWT from `{auth_url}/token/anonymous` (when configured).
- Signed in → the user's JWT from `NeonAuthRepository`.
- A fixed `api_key` is a shared client token and must be treated as public.

The JWT determines the Postgres role (`anonymous` or `authenticated`). Grant
table privileges to those roles, then add row-level security so a user can only
see their own rows.

```sql
alter table tasks enable row level security;

create policy "own tasks" on tasks
  for all
  to authenticated
  using (owner_id = auth.user_id())
  with check (owner_id = auth.user_id());
```

For anonymous access, decide explicitly what the `anonymous` role may read or
write. Never grant a service-role key to the app.

## Error mapping

| Backend result | Failure |
| --- | --- |
| 404 | `remote_database.not_found` |
| 5xx / transport | `remote_database.unavailable` |
| Other API error | `remote_database.query_failed` |

`read` returns `Ok(null)` for an absent row; update/delete produce
`remote_database.not_found`.

## Realtime

`watch` polls at `NeonConfig.watchInterval` (default five seconds). Provide a
`NeonChangeSignal` to re-poll immediately on a push hint; the interval remains a
backstop. Do not ship Neon's Realtime secret to the app.

## Testing

- Test the query serializer with a fake `http.Client` and assert the URL:
  repeated keys, list quoting, null filters, order, limit, offset.
- Test RLS with two users on a real Neon branch before release; an in-memory fake
  cannot prove Postgres policy.
- Test anonymous vs authenticated tokens separately.
