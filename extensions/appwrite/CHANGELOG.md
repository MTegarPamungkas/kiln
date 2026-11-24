# Changelog

## 0.3.4

- Update dependency constraints (`appwrite` `^28.4.1`, `shared_preferences` `^2.5.6`, `web` `^1.1.2`).

## 0.3.3

- Update the manifest and render golden tests for the shared Appwrite client
  capability and the web OAuth redirect URL, so the suite verifies the shipped
  brick again.

## 0.3.2

- Advertise the shared Appwrite client so dependent transports require the actual backend.

## 0.3.1

- Omit native OAuth redirect arguments so Appwrite returns the session
  credentials expected by the Flutter SDK. Reject unsupported custom native
  redirects before opening the provider browser.
- Own web OAuth popups so closing a window cancels promptly and permits retry.
  Validate callback origin, source window, path and a per-attempt identifier;
  close pending popups on logout/disposal and detach timers/listeners. Native
  OAuth continues to use the Appwrite SDK. Provider failures remain errors.
- Map row cursors to Appwrite queries and reject empty cursors or cursor/offset
  combinations. Revalidate client requests so browser storage reads cannot
  return cached bytes after deletion or replacement at the same file ID.
- Avoid introducing unused credential headers during session cleanup. A phantom
  Authorization header after a 401 could block later browser login via CORS.
- Declare Android API 24 and core library desugaring for the native/transitive
  plugins, including installation into existing Flutter applications.

- Realtime watches start when listened to and unsubscribe when their last
  listener cancels. Missing rows emit an initial null; stale reads cannot
  overwrite newer events, and equivalent nested payloads are deduplicated.
- Synchronous realtime setup errors become typed stream failures.
- Storage rejects unsupported URL expiry instead of silently ignoring it.
- OAuth generates a same-origin web callback page and supports a redirect
  override. Native browser cancellation returns null.
- Isolated live service tests create and clean up only resources they own.

- Session persistence is scoped to endpoint and project; unscoped legacy
  cookies are not restored. Secure storage is used for Kiln's session copy
  when the application's `SecureStorage` contract is available.
- Login, restore, JWT requests, and revocation have bounded request times.
  Native login follows the development-only self-signed certificate policy.
- Logout clears application state before remote revocation. Old login,
  restore, and JWT results cannot repopulate a cleared application session.
- JWT requests share a cache-generation request and use an injectable clock.
- Adapter lifecycle regression tests cover persistence, offline logout,
  cookie parsing, timeouts, local cleanup failures, and late responses.
- Sign-in works against Appwrite 2.7+, which URL-encodes the session cookie
  value. The extension now decodes it before sending `X-Appwrite-Session` and
  before seeding the SDK cookie jar.
- Registers the configured `appwrite.Client` so sibling transport extensions
  (such as `appwrite_push_native`) can subscribe on the same signed-in session.

## 0.3.0

- New `push_targets` capability: the `PushTargets` contract registers, updates, and removes the device's push token for the signed-in user through the Appwrite push target endpoints (one target per provider per session, upsert on token rotation).
- Adds the `push_targets.not_found` failure code and a `push_targets` failure-mapping scope.

## 0.2.1

- Declares the `token_provider` and `account_management` capabilities the module already registers, so `kiln doctor` capability coverage and backend-swap guidance see them.

## 0.2.0

- OAuth results now mark the Appwrite session JWT as a backend token and expose it through `backendSessionToken`; `accessToken` stays reserved for provider tokens.

- New `functions` capability: the `CloudFunctions` contract invokes functions
  deployed on the Appwrite project through `Functions.createExecution`, with
  execution status, response body, logs, and errors surfaced on
  `FunctionExecution`.
- Adds `functions.not_found` / `functions.unavailable` failure codes and a
  `functions` failure-mapping scope.

## 0.1.2

- Realtime receives authorized events again: the session cookie is mirrored
  into the SDK cookie jar, which the WebSocket handshake authenticates with.
  Header-based REST calls keep working unchanged.
- Realtime watch converges on the row's state shortly after subscribing: one
  delayed reconciliation read covers events Appwrite drops while the channel
  is still registering, and duplicate states are not re-emitted.
- Adds a live e2e suite that runs the auth, remote database, and file storage
  contracts against a real Appwrite server when `KILN_APPWRITE_E2E=1` is set;
  it skips itself otherwise.
- `tool/appwrite_e2e.dart` provisions a self-hosted project (database, tables,
  bucket, test user) and runs the suite in a rendered fixture app.

## 0.1.1

- Signing out clears the local session, cookie, and JWT even when the server
  cannot be reached.
- A persisted logout marker prevents a stale SDK cookie from reviving the
  previous account.

## 0.1.0

- Initial release.
