# appwrite

Implementation of `AuthRepository`, `RemoteDatabase`, and `FileStorage` from
`kiln_core` on top of [Appwrite](https://appwrite.io).

- `AppwriteAuth` uses the Appwrite `Account` to sign in, sign up, sign out, and
  restore a session that is still active.
- `AppwriteAccountManagement` handles password reset, email verification, and
  profile changes.
- `AppwriteSessionBridge` forwards the session to `SessionController` and provides
  a `TokenProvider` in the form of a short-lived Appwrite JWT.
- `AppwriteRemoteDatabase` maps `RemoteQuery` to TablesDB queries and
  forwards realtime changes through `watch`.
- `AppwriteFileStorage` uploads, downloads, links, and deletes files
  in the selected bucket.
- All SDK calls sit behind a gateway, so the app can test
  its flows without a network.

## Installing

```bash
kiln add appwrite
```

Prompts requested: `endpoint`, `project_id`, `database_id`, and `bucket_id`.
After installing, follow [docs/appwrite-setup.md](docs/appwrite-setup.md) and
complete the two manual steps recorded by `kiln doctor`: add the app
platform and register the redirect URLs `kiln://auth/recovery` and
`kiln://auth/verify`.

## Usage example

```dart
final auth = registry.read<AuthRepository>();
final session = await auth.signIn(
  email: 'user@kiln.dev',
  password: 'password123',
);

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
```

Query mapping, document permissions, and behavior differences are covered in
[docs/collections-and-permissions.md](docs/collections-and-permissions.md) and
[docs/backend-swap-notes.md](docs/backend-swap-notes.md).

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
