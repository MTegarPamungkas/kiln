# appwrite

Implementation of `AuthRepository`, `SocialAuth`, `RemoteDatabase`,
`FileStorage`, and `CloudFunctions` from `kiln_core` on top of
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
```

Prompts requested: `endpoint`, `project_id`, `database_id`, and `bucket_id`.
After installing, follow [docs/appwrite-setup.md](docs/appwrite-setup.md) and
complete the manual steps recorded by `kiln doctor`: add the app platform,
register the redirect URLs `kiln://auth/recovery` and `kiln://auth/verify`, and
enable the OAuth2 providers you want to use.

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

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
