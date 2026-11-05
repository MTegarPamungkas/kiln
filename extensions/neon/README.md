# Neon

Remote database access to [Neon](https://neon.tech) Lakebase Postgres for Kiln
apps. `neon` implements the `kiln_core` `RemoteDatabase` contract over the
**Neon Data API** — a PostgREST-compatible HTTP endpoint — so you create, read,
update, query, and watch rows through the Gate without owning any UI.

It is a real connector extension: it registers a `RemoteDatabase` service and
the SDK owns no UI. It is the `remote_database`-only counterpart to the
Supabase, Firebase, and Appwrite connectors, which bundle auth and storage as
well. Pick exactly one remote database provider per app.

## Install

```sh
kiln add neon
```

The installer prompts for the **Data API URL**, a **bearer token**, and a
**schema**. Only the `remote_database` capability is registered; add
`rest_auth` or a vendor connector if you also need login or files.

## Configuration

`NeonConfig` is rendered from the prompts:

- `dataApiUrl` — PostgREST-compatible Data API base URL.
- `apiKey` — bearer token sent on every request (a client-safe token, never a
  service-role key).
- `schema` — Postgres schema exposed through the Data API, sent as
  `Accept-Profile`/`Content-Profile`.
- `watchInterval` — how often [watch](#watch) polls a row (default five
  seconds).

## Usage

```dart
final gate = ...; // your Gate

// One call, one Result.
final created = await gate.remoteCreate('tasks', {'title': 'Write docs'});
final id = created.value?['id'];

final page = await gate.remoteQuery(
  'tasks',
  query: RemoteQuery(
    filters: [RemoteFilter('done', RemoteFilterOperator.equals, false)],
    orderBy: [RemoteOrder('created_at', direction: RemoteSortDirection.descending)],
    limit: 20,
  ),
);

// Realtime is simulated by polling the row (see Behavior).
final subscription = gate.remoteDb.watch('tasks', '$id').listen((row) {
  if (row != null) rebuildUi(row);
});
```

## Behavior

- Every operation returns a `Result` through the Gate; errors map to
  `Failure(remote_database.*)` (`notFound` for a missing row, `unavailable` for
  5xx or transport failures, `queryFailed` for other API errors).
- The Data API has no websocket, so `watch` polls the row on a timer and emits
  whenever its content changes. It satisfies the `RemoteDatabase` contract but
  has up to `watchInterval` of latency. For push-based realtime use the Supabase
  or Appwrite connector.
- Table and column names are validated as PostgREST identifiers before any
  request is built, so a malformed name fails as `validation.invalidInput`.
- A missing or invalid URL/token reports `notConfigured` in `kiln doctor`
  without reaching the network.

## Security note

The Neon Data API is PostgREST in front of your database. When a single bearer
token is shared by all clients, everything it can reach is reachable from the
app — so **enforce authorization with Postgres row-level security and a
per-user Neon Auth JWT**, and never embed a privileged key. See the Data API
guidance in Neon's docs before exposing it to untrusted clients.
