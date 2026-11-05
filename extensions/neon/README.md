# Neon

Remote database and object storage for [Neon](https://neon.tech) apps. `neon`
implements two `kiln_core` contracts over the Neon backend — **`RemoteDatabase`**
over the Data API (a PostgREST-compatible endpoint) and **`FileStorage`** over
Object Storage (S3-compatible) — so you create, read, update, query, and watch
rows, and upload/download/share files, through the Gate without owning any UI.

It is a real connector extension: it registers the services and the SDK owns no
UI. It is the counterpart to the Supabase, Firebase, and Appwrite connectors
minus auth — pick exactly one `RemoteDatabase` and one `FileStorage` provider
per app.

## Install

```sh
kiln add neon
```

The installer prompts for the **Data API URL**, a **bearer token**, and a
**schema** (database), plus the **Object Storage endpoint**, **bucket**,
**region**, **access key id**, and **secret** (files). Add `rest_auth` or a
vendor connector if you also need login.

## Configuration

Two typed configs are rendered from the prompts:

- `NeonConfig` — `dataApiUrl`, `apiKey`, `schema`, `watchInterval` (polling
  cadence, default five seconds).
- `NeonStorageConfig` — `endpoint`, `bucket`, `region`, `accessKeyId`,
  `secretAccessKey`, `signedUrlLifetime`.

## Usage

```dart
final gate = ...; // your Gate

// Database — one call, one Result.
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

// Storage — upload a file and get a signed link back.
final stored = await gate.uploadFile(
  FileUpload(path: 'avatars/user-1.png', bytes: pngBytes, contentType: 'image/png'),
);
final link = await gate.files.url('avatars/user-1.png');

// The Data API has no socket, so watch polls the row (see Behavior).
final subscription = gate.remoteDb.watch('tasks', '$id').listen((row) {
  if (row != null) rebuildUi(row);
});
```

## Behavior

- Every operation returns a `Result` through the Gate. Database errors map to
  `Failure(remote_database.*)` (`notFound` for a missing row, `unavailable` for
  5xx or transport failures, `queryFailed` for other API errors); storage errors
  map to `Failure(file.*)` (`fileNotFound`, `fileUploadFailed`, and so on).
- Because the Data API is request/response, `watch` polls the row on a timer and
  emits whenever its content changes. It satisfies the `RemoteDatabase` contract
  but has up to `watchInterval` of latency. For push realtime use Supabase or
  Appwrite.
- Table and column names are validated as PostgREST identifiers; file paths are
  validated before any request is built.
- S3 requests are signed with **AWS Signature Version 4** (path-style
  addressing), and `url` returns a **presigned** link.

## Security note

Both the Data API bearer token and the Object Storage keys are shipped to the
client in this direct-from-app setup, and each is privileged to everything it can
reach. **Enforce authorization with Postgres row-level security and a per-user
Neon Auth JWT, and scope the storage token to a single bucket with least
privilege** — never embed a service-role or broadly-scoped key. Review Neon's
Data API and Object Storage guidance before pointing an app at them.
