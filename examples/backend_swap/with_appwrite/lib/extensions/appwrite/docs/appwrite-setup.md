# Appwrite setup

## Native OAuth callbacks

Android, iOS and desktop login uses the SDK's default redirect. Kiln does not
send `success` or `failure` URL overrides on native platforms: even supplying
the default scheme explicitly prevents the server from returning the session
credentials the SDK expects. Keep the Android callback activity registered for
`appwrite-callback-<PROJECT_ID>`. Custom OAuth redirect overrides are web-only;
unsupported native overrides fail before opening the browser.

## Web OAuth cancellation

Kiln owns the web OAuth popup. Closing it returns `null` from social sign-in
and permits another attempt. A five-minute deadline also closes abandoned
popups. Logout and module disposal close an outstanding popup. Call sign-in
from a user gesture; a blocked popup reports a failure and can be retried.

Callbacks must be served from the application origin and use the generated
`web/kiln_appwrite_auth.html` handler (or an equivalent custom page posting
`kiln-appwrite-oauth` with its full callback URL). Keep its query parameters:
Kiln correlates the origin, source window, callback path and attempt ID before
accepting a response. Native flows continue through the Appwrite SDK.

Closing a popup cancels local delivery and browser navigation. It cannot undo
a session already created on the server before closure; logout revokes the
current Appwrite session. Google account sign-out is a separate action.

This extension talks to Appwrite Cloud or a self-hosted Appwrite instance.
Complete the following steps before using its contracts.

From your Kiln project, run `kiln add appwrite`, then `kiln setup appwrite`.
Setup collects the public client settings, saves them in `kiln.yaml`, and
regenerates the installed provider transactionally. Use `kiln doctor` to detect
missing or demo settings. The commands do not connect to Appwrite or create
console resources; complete the steps below and test sign-in in your app.

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

Kiln prints the platform reminder during installation and setup. It cannot
detect whether a platform has been created in the remote console.

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

Register an Android intent filter for recovery/verification in `MainActivity`. If the
application uses a different scheme, change `recoveryRedirectUrl` and
`verificationRedirectUrl` on `AppwriteAccountManagement` and make sure that
scheme is registered as a platform (type `scheme`) in the project.

### OAuth callbacks

OAuth uses the Appwrite SDK's `flutter_web_auth_2` browser flow. On Android,
add its callback activity inside the manifest's `<application>` element,
replacing `PROJECT_ID` with the actual project ID:

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true"
    android:taskAffinity="">
    <intent-filter android:label="flutter_web_auth_2">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="appwrite-callback-PROJECT_ID" />
    </intent-filter>
</activity>
```

On web, Kiln generates `web/kiln_appwrite_auth.html`; the default success URL
points to that page on the current origin. Deploy it alongside the app. For an
app served from a subdirectory, set `AppwriteConfig.oAuthRedirectUrl` to the
page's full URL on the same origin. Register the web hostname with Appwrite and
enable the desired OAuth provider. Native callback schemes must not be used as
web success URLs. Native browser cancellation returns `null`.

iOS uses the SDK's authentication session. Verify the bundle/platform setup and
complete the provider flow on an iOS device; generated code alone does not
verify the callback. The polling timeout starts after the browser call returns;
it does not forcibly close a provider browser that is still open.

### Storage links

`FileStorage.url(path)` returns a regular Appwrite view URL. Its accessibility
depends on bucket/file permissions and browser session cookies. Passing
`expiresIn` throws an unsupported `Failure`; this client adapter cannot mint
expiring file tokens. Generate those on a trusted backend instead.

## 6. Development

`AppwriteClientFactory` only calls `setSelfSigned` on the `development` flavor.
That way a local instance using a self-signed certificate can be used while
developing the application without loosening certificate checks in production.

A local instance without TLS uses the endpoint `http://<host>/v1`. From the
Android emulator, the host machine is reached via `http://10.0.2.2/v1`, not
`localhost`. Enable `android:usesCleartextTraffic="true"` only in debug builds so
Android allows HTTP. At runtime, `SupportRegistry` includes
`insecure_http: true` in the Appwrite support details when the configured
endpoint uses cleartext. This does not configure Android network security.

On native platforms, email/password sessions use a bounded HTTP request and
forward the returned cookie as `X-Appwrite-Session`. Browser sign-in uses the
Appwrite SDK's cookie flow. Session state is restored in `AppwriteModule.ready`
and cleared on sign-out.

Kiln scopes its persisted cookie to the endpoint and project. Install
`secure_storage` to use the application's secure-storage contract for Kiln's
copy; otherwise the compatibility store uses SharedPreferences. The vendor SDK
still manages its own cookie jar separately. See
[logout and session cleanup](logout-and-session-cleanup.md) for migration,
timeouts, local-storage failures, and concurrency behavior.
