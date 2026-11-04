# Appwrite setup

This extension talks to Appwrite Cloud or a self-hosted Appwrite instance.
Complete the following steps before using its contracts.

## 1. Create a project

1. Sign in to the Appwrite console and create a new project.
2. Copy the **Project ID** from the Settings page. This value becomes the
   `project_id` prompt.
3. Copy the API endpoint, for example `https://cloud.appwrite.io/v1` or
   `https://appwrite.example.com/v1`, into the `endpoint` prompt.

## 2. Register a platform

Appwrite rejects requests from platforms that are not registered. Add platforms
according to the application's targets:

- Android: package name from `applicationId`.
- iOS and macOS: bundle identifier.
- Web: hostname where the application is served.

The manual `appwrite_platform` step is reminded by `kiln doctor` until that
platform is created.

## 3. Database and tables

1. Create a database with the same id as the `database_id` prompt.
2. Create a table for each collection used by `RemoteDatabase`. The `collection`
   argument on the contract is used as the table id.
3. Define columns and indexes. Filters and `orderBy` need matching indexes, just
   like Appwrite queries in general.

## 4. Storage bucket

1. Create a bucket with the same id as the `bucket_id` prompt.
2. Choose the bucket permissions. For an application that only uploads files
   owned by the user, grant `create` and `read` permissions to the `users` role.
3. Set size and file type limits according to the application's needs.

## 5. Redirect URL

Password reset and email verification send the user back to the application via
a deep link. Appwrite 2.x no longer uses a redirect URL list in Auth Settings;
the scheme is validated against the project's platform list.

The mobile scheme that is always accepted is
`appwrite-callback-<PROJECT_ID>://`. The extension uses:

- `appwrite-callback-<PROJECT_ID>://auth/recovery`
- `appwrite-callback-<PROJECT_ID>://auth/verify`

Register an Android intent filter for that scheme in `MainActivity`. If the
application uses a different scheme, change `recoveryRedirectUrl` and
`verificationRedirectUrl` on `AppwriteAccountManagement` and make sure that
scheme is registered as a platform (type `scheme`) in the project.

## 6. Development

`AppwriteClientFactory` only calls `setSelfSigned` on the `development` flavor.
That way a local instance using a self-signed certificate can be used while
developing the application without loosening certificate checks in production.

A local instance without TLS uses the endpoint `http://<host>/v1`. From the
Android emulator, the host machine is reached via `http://10.0.2.2/v1`, not
`localhost`. Enable `android:usesCleartextTraffic="true"` only in debug builds so
Android allows HTTP. `kiln doctor` reports `insecure_http: true` in the Appwrite
support details when the configured endpoint uses cleartext, as a reminder that
the network security config is required.

Email/password sessions are created over HTTP and the cookie is forwarded as the
`X-Appwrite-Session` header. The SDK's built-in cookie jar is not always
persisted on plain HTTP endpoints, so this approach ensures subsequent calls are
already authenticated. The session value is stored via `shared_preferences`,
restored in `AppwriteModule.ready`, and removed on sign-out.
