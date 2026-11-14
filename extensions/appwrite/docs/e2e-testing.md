# Live e2e testing against Appwrite

The offline suites exercise every flow against in-memory fakes. When you own an
Appwrite server — Cloud or self-hosted — the same `kiln_testing` contract
suites can run against the real thing. The live suite renders the brick into a
fixture app and drives `AppwriteAuth`, `AppwriteRemoteDatabase`,
`AppwriteFileStorage`, the token provider, and realtime there.

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
