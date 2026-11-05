# Neon setup

The `neon` extension talks to one Neon project through its **Data API** — a
PostgREST-compatible HTTP endpoint in front of Lakebase Postgres — and its
**Object Storage** — an S3-compatible bucket. It registers the `RemoteDatabase`
and `FileStorage` contracts (not auth; add a login extension separately). All
rendered values come from `extension.yaml`; the rest live in `NeonConfig` and
`NeonStorageConfig`.

## 1. Enable the Data API

In the Neon Console (`console.neon.tech`), open your project and turn on the
Data API. Note the base URL — it looks like
`https://<endpoint>.aws.neon.tech/sql/rest` — and paste it into the
`data_api_url` prompt.

The Data API and its companion primitives are available only in supported
regions (`aws-us-east-2`, `aws-us-east-1`, `aws-eu-central-1`,
`aws-ap-southeast-1`). If your project is elsewhere, create it in one of those
regions first.

## 2. Provide a client-safe bearer token

The `api_key` prompt becomes the bearer token on every request (`Authorization:
Bearer <token>`). Use a token that is safe to ship in a client — a **per-user
Neon Auth JWT** guarded by row-level security — never a service-role key or a
token that carries a password.

> [!WARNING]
> A single bearer token shared by all clients exposes everything it can reach.
> Enforce authorization with Postgres **row-level security** so the token only
> sees the rows its user may access. Review Neon's Data API guidance before
> pointing an app at it.

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

The cadence is `NeonConfig.watchInterval` (default five seconds). Expect up to
one interval of latency and prefer `SupabaseRemoteDatabase` or
`AppwriteRemoteDatabase` when you need push-based realtime.

## 6. Object Storage

Neon Object Storage is S3-compatible and available only in the supported
regions. To use `FileStorage`:

1. Enable Object Storage on the project and create the bucket named in the
   `s3_bucket` prompt.
2. Issue a Neon token and note its **token id** (the `s3_access_key_id` prompt,
   the S3 access key id) and **S3 secret** (the `s3_secret_access_key` prompt,
   sent to the client here — scope it to this bucket).
3. Set `s3_endpoint` to the branch storage host, for example
   `https://<branch>.storage.c-<region>.aws.neon.tech`, and `s3_region` to the
   SigV4 region (for example `us-east-2`).

The connector signs every request with AWS Signature Version 4 using path-style
addressing (`endpoint/bucket/key`) and returns presigned links from `url`.

```dart
final stored = await gate.uploadFile(
  FileUpload(path: 'avatars/user-1.png', bytes: png, contentType: 'image/png'),
);
final link = await gate.files.url('avatars/user-1.png'); // presigned
final bytes = await gate.downloadFile('avatars/user-1.png');
```

## 7. Which realtime model do you need?

The Data API is request/response, so `watch` polls; Object Storage has no live
listing. If you need push-based database realtime, use the Supabase or Appwrite
connector instead.

## Local development

A locally running PostgREST (or a self-hosted stack) works with a plain `http`
`data_api_url`; set `NeonConfig.watchInterval` and the bearer token accordingly.
On Android, add a cleartext networking rule for the development host before
using an `http` endpoint.
