# Neon

Auth, remote database, and object storage for [Neon](https://neon.tech) apps.
`neon` implements three `kiln_core` contracts over the Neon backend:

- **`AuthRepository`** — email/password sign-in through **Neon Auth (Better
  Auth)**.
- **`RemoteDatabase`** — CRUD and polling `watch` over the **Data API**
  (PostgREST).
- **`FileStorage`** — upload/download/signed URLs over **Object Storage**
  (S3-compatible, SigV4-signed).

The SDK owns no UI; every call goes through the Gate and returns a `Result`.
`social_auth` is intentionally not provided — Better Auth social login is a
browser redirect, which the `deep_links`-based flow handles, not Kiln's native
`SocialAuth` contract.

## Install

```sh
kiln add neon
```

Prompts: the Data API URL, an optional bearer token, the Neon Auth base URL,
the Postgres schema, and the Object Storage endpoint/bucket/region/keys.

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

## Storage

```dart
final stored = await gate.uploadFile(
  FileUpload(path: 'avatars/user-1.png', bytes: bytes, contentType: 'image/png'),
);
final link = await gate.files.url('avatars/user-1.png'); // presigned
```

## Setup checklist

1. In the Neon Console, enable the **Data API** and **Neon Auth**; note the
   Data API URL (`…/rest/v1`) and the Auth base URL (`…/auth`).
2. Enable **Object Storage**, create a bucket, and issue a Neon credential
   (token id → access key id, S3 secret → secret key) scoped to that bucket.
3. Run the GRANT block above for any table the app touches, then
   `neon data-api refresh-schema`.
4. For per-user data, grant the `authenticated` role and add row-level security
   policies using `auth.user_id()`.

## Security note

The Data API token (or the anonymous JWT) and the Object Storage keys are
shipped to the client. Enforce authorization with Postgres **row-level
security** and scope the storage token to a single bucket — never embed a
service-role key. Review Neon's Data API and Object Storage guidance first.
