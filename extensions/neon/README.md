# Neon

Auth, remote database, and object storage for [Neon](https://neon.tech) apps.
`neon` implements three `kiln_core` contracts over the Neon backend:

- **`AuthRepository`** — email/password sign-in through **Neon Auth (Better
  Auth)**.
- **`RemoteDatabase`** — CRUD and `watch` over the **Data API** (PostgREST), with optional push-triggered refresh via a `NeonChangeSignal`.
  (PostgREST).
- **`FileStorage`** — upload/download/signed URLs over **Object Storage**,
  through an application-owned presigning backend that keeps the S3 credentials
  server-side.

The SDK owns no UI; every call goes through the Gate and returns a `Result`.
`social_auth` is intentionally not provided — Better Auth social login is a
browser redirect, which the `deep_links`-based flow handles, not Kiln's native
`SocialAuth` contract.

## Install

```sh
kiln add neon
```

Prompts: the Data API URL, an optional bearer token, the Neon Auth base URL,
the Postgres schema, the storage signing URL, and the Object Storage bucket.

## Quick start: anonymous database access

The fastest path needs no token plumbing. Provide the **`auth_url`** prompt and
leave `api_key` empty; the connector then fetches a short-lived anonymous JWT
from `{auth_url}/token/anonymous` automatically. Give the `anonymous` role
access to your tables once in the Neon **SQL Editor**:

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

Then refresh the Data API schema cache (`neon data-api refresh-schema`) and:

```dart
final created = await gate.remoteCreate('tasks', {'title': 'Write docs'});
final open = await gate.remoteQuery(
  'tasks',
  query: RemoteQuery(filters: [RemoteFilter('done', RemoteFilterOperator.equals, false)]),
);
```

## Auth

Sign in and out through the Gate; the signed-in user's JWT is forwarded to the
Data API automatically, so `remote_database` runs as the `authenticated` role:

```dart
final result = await gate.signIn(email: 'you@example.com', password: 'secret');
result.fold(
  ok: (session) => print('signed in as ${session.email}'),
  err: (failure) => print('${failure.code}'),
);

// The user is also available reactively:
gate.auth.authStateChanges.listen((session) { ... });
await gate.signOut();
```

Sessions live in memory for the app process; wire a persistent store for
surviving restarts.

## Realtime

`watch` polls the row every `NeonConfig.watchInterval` (default five seconds).
For faster refresh, give the module a `NeonChangeSignal` and emit hints from
your own push channel — a matching hint re-polls the row immediately:

```dart
final module = NeonModule(config: config, changeSignal: mySignal);
mySignal.emit(table: 'tasks', id: '42'); // re-poll now
```

See `docs/neon.md` for the Neon Realtime (beta) pattern: your backend
subscribes with the official TypeScript SDK and pushes hints to the app, which
never holds the Realtime secret.

## Storage

```dart
final stored = await gate.uploadFile(
  FileUpload(path: 'avatars/user-1.png', bytes: bytes, contentType: 'image/png'),
);
final link = await gate.files.url('avatars/user-1.png');
```

The app never holds an S3 key. `storage_signing_url` points to a backend you
deploy; it receives the signed-in user's Neon Auth JWT and returns
`{url, headers?}` for one scoped upload/download/delete. The signing endpoint
must verify the JWT and per-user object ownership, keep the S3 credentials
server-side, and issue URLs valid for at most 900 seconds. See
[docs/neon.md](docs/neon.md#6-object-storage) for the request/response contract.

## Setup checklist

1. In the Neon Console, enable the **Data API** and **Neon Auth**; note the
   Data API URL (`…/rest/v1`) and the Auth base URL (`…/auth`).
2. Enable **Object Storage** and create the bucket named in the prompt. Keep the
   S3 access key and secret on your signing backend, never in the app.
3. Run the GRANT block above for any table the app touches, then
   `neon data-api refresh-schema`.
4. For per-user data, grant the `authenticated` role and add row-level security
   policies using `auth.user_id()`.

## Security note

The Data API token or anonymous JWT is a client credential; enforce
authorization with Postgres **row-level security**. Never embed a service-role
key. Object Storage uses a user-JWT presigning backend, so the app never carries
an S3 credential. Review Neon's Data API and Object Storage guidance before
pointing an app at a production project.
