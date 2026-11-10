# supabase

Implementation of the `kiln_core` contracts on top of `supabase_flutter`: `AuthRepository`,
`SocialAuth`, `AccountManagement`, `RemoteDatabase`, and `FileStorage`, plus
`TokenProvider`, the session bridge, and the email callback handler.

- `SupabaseAuthRepository` uses Supabase email and password, keeps the session
  in memory, and forwards `onAuthStateChange` to `authStateChanges`.
- `SupabaseSocialAuth` exchanges a Google or Apple ID token through
  `signInWithIdToken`; without an ID token source, the extension opens the OAuth
  flow in the browser and waits for the deep link callback.
- `SupabaseAccountManagement` handles password reset, email verification, and
  changes to `display_name`/`avatar_url`.
- `SupabaseRemoteDatabase` maps `RemoteQuery` to PostgREST filters and
  uses realtime for `watch`.
- `SupabaseFileStorage` uses a single bucket and always creates signed URLs.
- `SupabaseSessionBridge` forwards the session to `SessionController`, while
  `SupabaseTokenProvider` reads the access token of the active session.
- `SupabaseLinkHandler` handles `code` (PKCE) and `token_hash`/`type`
  (email verification) through the `DeepLinks` contract.

## How to install

```bash
kiln ext add supabase
```

Fill the `url` and `anon_key` prompts from the Supabase dashboard. After
rendering, complete the manual steps in `extension.yaml`:

1. `configure_auth_redirect` — match `authRedirectUrl` with the scheme used by
   the `deep_link` extension.
2. `enable_realtime` — add the tables being `watch`ed to the
   `supabase_realtime` publication.
3. `create_storage_bucket` — create a `public` bucket or change
   `SupabaseConfig.storageBucket`.

### Local and self-hosted stacks

A `supabase start` (Docker) API is `http://localhost:54321`. `supabase_flutter`
accepts the plain `http` URL, so use `http://127.0.0.1:54321` on desktop and web
and `http://10.0.2.2:54321` on the Android emulator; the support report flags
`insecure_http`. On Android you also need a debug cleartext rule. See
[Supabase setup](docs/supabase-setup.md), section 6.

## Usage example

```dart
final auth = registry.read<AuthRepository>();
await auth.signIn(email: 'user@kiln.dev', password: 'password123');

final db = registry.read<RemoteDatabase>();
final tasks = await db.query(
  'tasks',
  query: const RemoteQuery(
    filters: [RemoteFilter('done', RemoteFilterOperator.equals, false)],
    orderBy: [RemoteOrder('title')],
    limit: 20,
  ),
);
```

Further documentation:

- [Supabase setup](docs/supabase-setup.md)
- [Row level security](docs/row-level-security.md)
- [Email confirmation and redirect](docs/email-confirmation-and-redirects.md)

## Gate

```dart
final session = await gate.signIn(email: email, password: password);
final doc = await gate.remoteRead('users', id);
final file = await gate.uploadFile(upload);
```

Every call returns a `Result`; the app owns the UI.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
