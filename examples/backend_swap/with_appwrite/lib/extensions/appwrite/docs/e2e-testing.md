# Live e2e testing against Appwrite

## Android and web service probes

With `KILN_APPWRITE_ENDPOINT`, `KILN_APPWRITE_PROJECT` and
`KILN_APPWRITE_API_KEY` set in the host environment, run from the repository:

```powershell
node tool/e2e/run_platform_probe.mjs --services --android --web
$env:KILN_APPWRITE_PUSH_ENDPOINT = 'mqtts://push.example.com:8883'
node tool/e2e/run_platform_probe.mjs --push --android
```

Start the Android emulator first. Service mode creates an isolated temporary
database, tables, bucket and user. Push mode creates a temporary user and
Appwrite messaging provider and sends only to that user. The helper backend
uses memory. The API key stays on the host; credentials are not rendered into
client source. Reports and credential-free ownership journals are written under
`.dart_tool/`; inspect cleanup errors before repeating an interrupted run.

Native push requires a reachable TLS MQTT broker with a valid certificate.
Opening a firewall port alone does not start the broker or configure its TLS.
This extension does not support browser push. Background/tray/tap acceptance
requires separate device checks; the automated push mode checks foreground
delivery and logout only. The complete coordinator still needs a clean-fixture
end-to-end rerun; current device evidence used its fixtures and host helper.

Google OAuth requires an enabled Google provider with its client ID/secret and
approved callback URLs configured in Appwrite and Google. Service and push
probes do not establish successful OAuth login.

For minimal Android/web auth, router and Dio functional checks without an
additional database, use `node tool/e2e/run_platform_probe.mjs` from the Kiln
repository with the endpoint/project/API-key environment configured below.
It validates auth against Appwrite and CRUD against a loopback memory backend;
it does not run the Appwrite database/storage contracts. Test credentials are
supplied at runtime and the server key stays in the host coordinator.

The offline suites exercise every flow against in-memory fakes. When you own an
Appwrite server — Cloud or self-hosted — the same `kiln_testing` contract
suites can run against the real thing. The live suite renders the brick into a
fixture app and drives `AppwriteAuth`, `AppwriteRemoteDatabase`,
`AppwriteFileStorage`, the token provider, and realtime there.

## Auth-only testing on an existing project

Set `KILN_APPWRITE_ENDPOINT`, `KILN_APPWRITE_PROJECT`, and
`KILN_APPWRITE_API_KEY` in the process environment, then run:

```bash
dart run tool/appwrite_e2e.dart auth
```

This mode creates one temporary user with a random password, renders an
isolated fixture under `.dart_tool/`, and runs six live checks: initial signed-out
state, valid login, invalid credentials, logout, JWT creation, and persistence
across adapter restarts. The final check also verifies that the old session is
rejected by the server after logout.

The temporary user is deleted in `finally`. This command does not invoke the
broader cleanup used by `provision`, `run`, or `clean`; it does not create or
change databases, buckets, or existing users. The API key needs permissions to
create and delete users and is removed from the Flutter test process environment.
The password is generated in memory, and credentials are not written to the
fixture. A credential-free summary is saved to
`.dart_tool/appwrite_auth_result.json`, including the test count and cleanup result.

Auth-only mode deliberately excludes account registration, database, storage,
realtime, push, and deployed-function tests. Use the full suite below only with
dedicated test resources: its cleanup removes matching test users and all rows
and files in the configured test tables and bucket.

## Isolated service testing on an existing project

With the same endpoint, project, and API key environment variables, run:

```bash
dart run tool/appwrite_e2e.dart services
```

This creates a unique temporary user, database, tables/indexes, and bucket.
Nine live checks cover database CRUD/query/update/delete/missing reads,
realtime updates/deletion/initial missing row, storage round trips/progress,
and push target registration/update/removal. All resources created by this run
are deleted in `finally`; cleanup continues if deleting one resource fails.
The report `.dart_tool/appwrite_services_result.json` lists any cleanup still
pending. Existing databases, buckets, and users are not modified. The key needs
the corresponding users, database/schema, storage, and cleanup scopes.

The child Flutter process does not receive the server API key. This mode does
not verify device notification delivery, OAuth, recovery mail, or functions.
Prefer it to the broad cleanup commands below when using an existing project.

`dart run tool/appwrite_e2e.dart render` prepares an offline test fixture at
`.dart_tool/appwrite_platform` using only endpoint/project settings. Run
selected browser-compatible tests there with `flutter test --platform chrome`.
The live suite and native session-lifecycle tests import `dart:io`; do not run
the entire test directory in a browser.

## 1. Prepare the environment

Export the connection settings. The API key is read by the tool only and is
never written to disk or committed.

```bash
export KILN_APPWRITE_E2E=1
export KILN_APPWRITE_ENDPOINT=https://appwrite.example.com/v1
export KILN_APPWRITE_PROJECT=<project id>
export KILN_APPWRITE_API_KEY=<key with databases, storage, and users scopes>
export KILN_APPWRITE_TEST_EMAIL=e2e@example.com
export KILN_APPWRITE_TEST_PASSWORD=password123
```

`KILN_APPWRITE_DATABASE` and `KILN_APPWRITE_BUCKET` override the `kiln` and
`kiln_files` defaults when the project uses other ids.

Without `KILN_APPWRITE_E2E=1` the live suite skips itself, so the extension's
offline tests, CI, and generated apps are unaffected.

## 2. Provision the project

```bash
dart run tool/appwrite_e2e.dart provision
```

The tool talks to the server's REST API and is idempotent — run it as often as
you like. It:

1. removes leftovers from earlier runs (signup users, rows, files),
2. creates the database with the `users` and `tasks` tables (columns, indexes,
   and `users`-role permissions for row CRUD),
3. creates the bucket with `users`-role permissions,
4. creates or refreshes the test user from the email/password variables.

`dart run tool/appwrite_e2e.dart clean` only removes the leftovers, and
`provision` reports the server it talked to so a wrong `KILN_APPWRITE_ENDPOINT`
fails fast.

## 3. Run the suite

```bash
dart run tool/appwrite_e2e.dart run
```

The command renders the brick into `e2e_appwrite/` at the repository root
(git-ignored), cleans leftovers from earlier runs (signup users, rows, files),
runs `flutter pub get`, and executes
`test/extensions/appwrite/appwrite_e2e_test.dart` inside that fixture. The
suite runs the auth, remote database, and file storage contracts plus the
token provider and realtime delete flows against the live server, and `run`
can be repeated as often as needed.

What is intentionally not covered live:

- **Social sign-in** — OAuth needs a configured provider and a browser round
  trip; the fake covers the polling and credential mapping.
- **Password recovery and email verification** — these require SMTP on the
  server. Configure SMTP and extend the suite if you need them live.
- **Per-user document permissions** — the provisioned tables grant row CRUD to
  the `users` role; permission-denied mapping stays under the offline suites.

## Notes for self-hosted servers

- Cleartext `http://` endpoints work in the development flavor; the fixture
  module runs with `AppFlavor.development`, matching the setup guide.
- From an Android emulator the endpoint is `http://10.0.2.2/v1`, not
  `localhost`.
- Appwrite processes schema changes asynchronously; `provision` waits until
  the columns and indexes report `available` before finishing.
- Rotate the API key after testing if it passed through any channel you do not
  control, and keep the key scoped to this one project.
