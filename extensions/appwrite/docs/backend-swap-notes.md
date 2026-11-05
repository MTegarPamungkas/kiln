# Backend migration notes

The `AuthRepository`, `RemoteDatabase`, and `FileStorage` contracts are the same
as in the Firebase and Supabase extensions, but there are several behavioral
differences to know when moving an application to Appwrite.

## Auth

- `signUp` creates an account and then immediately creates a session. If the
  project requires email verification before sign-in, this call fails with
  `Failure(auth.email_not_verified)`.
- Sessions are created over HTTP and the cookie is sent as the
  `X-Appwrite-Session` header; its value is stored in `shared_preferences` and
  restored by `AppwriteModule.ready` when the application is reopened.
- `AppwriteTokenProvider` creates a 15-minute JWT and caches it for 14 minutes.
  This token is used for HTTP requests that need a bearer token, not to replace
  the main session.
- Password reset and email verification use the
  `appwrite-callback-<PROJECT_ID>://auth/recovery` and `.../auth/verify` schemes.
  Appwrite 2.x accepts those schemes without a redirect URL list.

## Database

- There is no offline cache. Every `read` and `query` hits the network; use the
  `local_db` extension if the application needs offline mode.
- Collection names are mapped to table ids. Returned documents contain `id` and
  ordinary columns, without Appwrite system columns.
- `watch` emits the current document first, then realtime changes, and emits
  null when the document is deleted. The subscription is closed when the module
  is disposed.
- Combinations of filters and ordering still require indexes. Appwrite rejects
  queries without an index with `Failure(remote_database.query_failed)` or
  `Failure(remote_database.unavailable)`.

## Storage

- Paths such as `avatars/user-1.png` are mapped to a valid Appwrite file id. The
  original name remains visible in the `view` URL.
- `expiresIn` on `FileStorage.url` is ignored because the client SDK cannot
  create a signed URL. Make the bucket public or create signed URLs from the
  server.
- `updatePhotoUrl` stores the URL in the user preferences under the `photoUrl`
  key, because Appwrite has no built-in profile photo column.

## Failure mapping

| Status | Failure |
| --- | --- |
| 400 | `validation.invalid_input` |
| 401 wrong credentials | `auth.invalid_credentials` |
| 401 email not verified | `auth.email_not_verified` |
| 401 session missing | `auth.session_expired` |
| 401 other | `auth.unauthorized` |
| 403 | `permission.denied` |
| 404 database | `remote_database.not_found` |
| 404 storage | `file.not_found` |
| 409 database | `remote_database.conflict` |
| 409 storage | `file.upload_failed` |
| 429 | `network.server` with `isRetryable` |
| 5xx | `unavailable` with `isRetryable` |
| network error | `network.unreachable` or `network.unknown` |
