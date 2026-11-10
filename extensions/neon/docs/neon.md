# Neon setup

The `neon` extension talks to one Neon project through **Neon Auth** (Better
Auth), the **Data API** — a PostgREST-compatible HTTP endpoint in front of
Lakebase Postgres — and **Object Storage** — an S3-compatible bucket. It
registers the `AuthRepository`, `RemoteDatabase`, and `FileStorage` contracts.
All rendered values come from `extension.yaml`; the rest live in `NeonConfig`
and `NeonStorageConfig`.

## 1. Enable the Data API

In the Neon Console (`console.neon.tech`), open your project and turn on the
Data API. Note the base URL and paste it into the `data_api_url` prompt. The URL
is compute/branch-specific and looks like
`https://<compute-or-branch>.apirest.c-2.<region>.aws.neon.tech/<db>/rest/v1`.
Neon embeds a cluster segment (for example `c-2`) **before** the region, so copy
the exact host from the console or `neon data-api get` rather than
hand-assembling it.

The Data API and its companion primitives are available only in supported
regions (`aws-us-east-2`, `aws-us-east-1`, `aws-eu-central-1`,
`aws-ap-southeast-1`). If your project is elsewhere, create it in one of those
regions first.

## 2. Authentication

The Data API requires a bearer token on **every** request — Neon rejects
anonymous calls with *"required authorization bearer token in JWT format"*. The
connector supplies that token one of two ways:

- **Fixed token (`api_key`)** — a Neon Auth JWT you provide.
- **Anonymous JWT (`auth_url`)** — leave `api_key` empty and set `auth_url` to
  the Neon Auth base URL (`https://<…>.neonauth.c-2.<region>.aws.neon.tech/<db>/auth`).
  The connector fetches `{auth_url}/token/anonymous` automatically and caches it,
  so `remote_database` runs as the `anonymous` role with zero token plumbing.

### Email/password sign-in

`neon` also provides `AuthRepository` over Neon Auth:

```dart
final result = await gate.signIn(email: 'you@example.com', password: 'secret');
// The signed-in user's JWT is forwarded to the Data API automatically, so
// remote_database runs as the `authenticated` role until signOut.
await gate.signOut();
```

### Grants for the anonymous / authenticated roles

Run once in the Neon SQL Editor, then `neon data-api refresh-schema`:

```sql
create table if not exists tasks (
  id bigint generated always as identity primary key,
  title text,
  done boolean not null default false
);
grant usage on schema public to anonymous, authenticated;
grant select, insert, update, delete on tasks to anonymous, authenticated;
grant usage, select on sequence tasks_id_seq to anonymous, authenticated;
```

> [!WARNING]
> A token shared by all clients exposes everything it can reach. Enforce
> authorization with Postgres **row-level security** (using `auth.user_id()`)
> and scope the Object Storage token to one bucket. Never ship a service-role
> key. Review Neon's Data API guidance before pointing an app at it.

## 3. Schema

The `schema` prompt is the Postgres schema exposed through the Data API. It
defaults to `public`. The value is sent as `Accept-Profile` (reads) and
`Content-Profile` (writes), and is validated as a PostgREST identifier.

## 4. Usage through the Gate

```dart
final gate = ...; // your Gate

final created = await gate.remoteCreate('tasks', {'title': 'Write docs'});
final id = created.value?['id'];

final open = await gate.remoteQuery(
  'tasks',
  query: RemoteQuery(
    filters: [RemoteFilter('done', RemoteFilterOperator.equals, false)],
    orderBy: [RemoteOrder('created_at', direction: RemoteSortDirection.descending)],
    limit: 20,
  ),
);

await gate.remoteUpdate('tasks', '$id', {'done': true});
await gate.remoteDelete('tasks', '$id');
```

Every call returns a `Result`. A missing row is `Failure(remote_database.notFound)`,
a 5xx or transport error is `Failure(remote_database.unavailable)`, and other API
errors are `Failure(remote_database.queryFailed)`.

## 5. Watching a row

The Data API is request/response, so `watch` polls the row on a timer and emits
whenever its content changes:

```dart
final subscription = gate.remoteDb.watch('tasks', '$id').listen((row) {
  if (row == null) {
    // deleted
  } else {
    rebuildUi(row);
  }
});
// later
await subscription.cancel();
```

The cadence is `NeonConfig.watchInterval` (default five seconds), so expect up
to one interval of latency. To refresh faster, hand the module a
`NeonChangeSignal` and emit a hint whenever the app learns that rows changed —
from a push notification, a socket, or any other out-of-band channel. A matching
hint re-polls the row immediately; the interval stays as a backstop for missed
hints:

```dart
final module = NeonModule(config: config, changeSignal: mySignal);

// Later, wherever the app hears about a change (here: an FCM data message):
FirebaseMessaging.onMessage.listen((message) {
  mySignal.emit(table: message.data['table'], id: message.data['id']);
});
```

Hints are best-effort: `table` or `id` may be null to match everything, and a
hint that never arrives only means the watch refreshes on the interval as
before.

## 6. Object Storage

Neon Object Storage is S3-compatible and available only in the supported
regions. The app never holds an S3 key: a small signing backend you own scopes
each operation to the signed-in user.

1. Enable Object Storage on the project and create the bucket named in the
   `s3_bucket` prompt.
2. Deploy an HTTPS signing endpoint and set `storage_signing_url` to it. It
   receives `POST` JSON:

   ```json
   {"operation": "upload", "bucket": "files", "key": "avatars/user-1.png",
    "contentType": "image/png", "metadata": {}, "expiresIn": 300}
   ```

   with `Authorization: Bearer <Neon Auth JWT>`. The backend must verify that
   JWT, enforce per-user object ownership, keep the S3 credentials server-side,
   and answer `{"url": "<short-lived presigned URL>", "headers": {…}}`. Keep
   `expiresIn` at or below 900 seconds.

The connector calls the signing endpoint for `upload`, `download`, and
`delete`, then uses the returned URL and headers. The bearer token is sent only
to the signing backend, never to the object host, and redirects are disabled on
both legs. `FileStorage.url` asks for a download URL, so it fails when the
backend requires extra headers that a bare URL cannot carry.

```dart
final stored = await gate.uploadFile(
  FileUpload(path: 'avatars/user-1.png', bytes: png, contentType: 'image/png'),
);
final link = await gate.files.url('avatars/user-1.png'); // presigned
final bytes = await gate.downloadFile('avatars/user-1.png');
```

## 7. Which realtime model do you need?

The Data API is request/response, so `watch` polls and a `NeonChangeSignal`
carries freshness from your own push channel. Neon's **Realtime (beta)** fits
that shape: its wire protocol is undocumented and unsupported for direct
clients, and its branch-scoped secret must never ship inside an app, so run it
on your backend instead — subscribe there with the official `@neon/realtime`
TypeScript SDK and push a hint to the app (FCM, socket) on every change. The app
never holds the Realtime secret or speaks the beta protocol, and the Data API
keeps enforcing Neon Auth JWTs and Postgres RLS. When Neon documents the wire
protocol or ships a Dart SDK, this connector can adopt it behind the same
`RemoteDatabase.watch` contract. For push-based realtime with no backend of
your own, use the Supabase or Appwrite connector instead.

## Local development

A locally running PostgREST (or a self-hosted stack) works with a plain `http`
`data_api_url`; set `NeonConfig.watchInterval` and the bearer token accordingly.
On Android, add a cleartext networking rule for the development host before
using an `http` endpoint.
