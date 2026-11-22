# appwrite

Implementation of `AuthRepository`, `SocialAuth`, `RemoteDatabase`,
`FileStorage`, `CloudFunctions`, and `PushTargets` from `kiln_core` on top of
[Appwrite](https://appwrite.io).

- `AppwriteAuth` uses the Appwrite `Account` to sign in, sign up, sign out, and
  restore a session that is still active.
- `AppwriteSocialAuth` runs Google/Apple sign-in through the Appwrite OAuth2
  redirect flow and returns a `SocialCredential`, matching the Supabase and
  Firebase backends.
- `AppwriteAccountManagement` handles password reset, email verification, and
  profile changes.
- `AppwriteSessionBridge` forwards the session to `SessionController` and provides
  a `TokenProvider` in the form of a short-lived Appwrite JWT.
- `AppwriteRemoteDatabase` maps `RemoteQuery` to TablesDB queries and
  forwards realtime changes through `watch`.
- `AppwriteFileStorage` uploads, downloads, links, and deletes files
  in the selected bucket.
- `AppwriteFunctions` invokes cloud functions deployed on the project and
  returns the execution result.
- All SDK calls sit behind a gateway, so the app can test
  its flows without a network.

## Installing

```bash
kiln add appwrite
kiln setup appwrite
kiln doctor
```

Settings: `endpoint`, `project_id`, `database_id`, and `bucket_id`. The setup
wizard reviews saved values and replaces the demo project ID with your real
project. Explicit `--answer` values override saved settings. No server API key
is needed. Preview changes with `kiln setup appwrite --dry-run`.

Setup updates client settings, generated source, and ownership hashes in one
transaction. Modified extension files are protected; failed verification rolls
the setup back. Doctor checks local configuration and points to setup commands
for missing or invalid settings. Neither command checks the remote server.

After configuring, follow [docs/appwrite-setup.md](docs/appwrite-setup.md): add
your app platforms and configure the resources, permissions, and authentication
flows your app uses.

## Usage example

```dart
final auth = registry.read<AuthRepository>();
final session = await auth.signIn(
  email: 'user@kiln.dev',
  password: 'password123',
);

// Social sign-in (Google/Apple). Returns null when the user cancels.
final social = registry.read<SocialAuth>();
final credential = await social.signIn(SocialProvider.google);

final database = registry.read<RemoteDatabase>();
final tasks = await database.query(
  'tasks',
  query: const RemoteQuery(
    filters: [RemoteFilter('done', RemoteFilterOperator.equals, false)],
    orderBy: [RemoteOrder('title')],
    limit: 20,
  ),
);

final storage = registry.read<FileStorage>();
final stored = await storage.upload(
  FileUpload(path: 'avatars/user-1.png', bytes: bytes),
  onProgress: (progress) => debugPrint('${progress * 100}%'),
);

// Invoke a function deployed on the project (extension 0.2.0+).
final functions = registry.read<CloudFunctions>();
final execution = await functions.invoke('hello-kiln', body: {'name': 'Kiln'});
debugPrint(execution.bodyJson?['message']);
```

Query mapping, document permissions, and behavior differences are covered in
[docs/collections-and-permissions.md](docs/collections-and-permissions.md) and
[docs/backend-swap-notes.md](docs/backend-swap-notes.md). Offline logout and
session cleanup are covered in
[docs/logout-and-session-cleanup.md](docs/logout-and-session-cleanup.md).

## Live e2e suite

The same contract suites run against a real Appwrite server — Cloud or
self-hosted — through `tool/appwrite_e2e.dart`. The live suite skips itself
unless the `KILN_APPWRITE_E2E` environment is set, so offline tests and CI stay
hermetic. See [docs/e2e-testing.md](docs/e2e-testing.md) for the provisioning
and run commands.

## Gate

```dart
final session = await gate.signIn(email: email, password: password);
final doc = await gate.remoteCreate('users', {'name': 'Ana'});
final file = await gate.uploadFile(upload);
await gate.sendPasswordReset(email);
```

Every call returns a `Result`; the app owns the UI.

## Runtime support

Session persistence is scoped per endpoint and project. With `secure_storage`
installed, Kiln uses the `SecureStorage` contract for its session copy; otherwise
it uses SharedPreferences. The vendor SDK's cookie jar remains independently
managed. Email/password auth requests are bounded, logout works offline, and
late restore/JWT results cannot restore cleared application state. See
[session lifecycle details](docs/logout-and-session-cleanup.md).

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
