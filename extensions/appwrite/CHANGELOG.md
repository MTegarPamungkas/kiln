# Changelog

## 0.3.0

- New `push_targets` capability: the `PushTargets` contract registers, updates, and removes the device's push token for the signed-in user through the Appwrite push target endpoints (one target per provider per session, upsert on token rotation).
- Adds the `push_targets.not_found` failure code and a `push_targets` failure-mapping scope.

## 0.2.1

- Declares the `token_provider` and `account_management` capabilities the module already registers, so `kiln doctor` capability coverage and backend-swap guidance see them.

## 0.2.0

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
