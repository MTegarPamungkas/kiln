# Email confirmation and redirects

Supabase sends the user back to the app through two link shapes:

- `?code=...` for the PKCE flow, such as OAuth login and password reset.
- `?token_hash=...&type=...` for email confirmation, invites, and magic links.

`SupabaseLinkHandler` reads both from the `DeepLinks` contract, then calls
`exchangeCodeForSession` or `verifyOtp`. If the `deep_link` extension is not
installed, the handler does nothing and the app must handle the links itself.

## 1. Match the scheme

`SupabaseConfig.authRedirectUrl` defaults to `kiln-auth://auth-callback` and the
extension manifest registers the `kiln-auth` scheme for Android and iOS.
Configure the `deep_link` extension with the same scheme:

```yaml
# extension.yaml deep_link
prompts:
  - name: scheme
    default: kiln-auth
```

If the scheme is changed, also change `authRedirectUrl` in
`supabase_config.dart` and register that scheme in the `deep_link` extension
manifest.

## 2. Register the URL in the dashboard

In **Authentication > URL configuration**:

- **Site URL** is filled with the app page or `kiln-auth://auth-callback`.
- **Redirect URLs** adds every redirect in use, for example
  `kiln-auth://auth-callback`.

Supabase rejects a `redirectTo` that is not in this list.

## 3. Enable email confirmation

In **Authentication > Providers > Email** enable **Confirm email**. After that
`signUp` returns an empty session and the extension throws
`Failure(auth.email_not_verified)`. The user must open the confirmation link
first, after which `signIn` can be used.

## 4. Password reset flow

```dart
final account = registry.read<AccountManagement>();
await account.sendPasswordResetEmail('user@kiln.dev');
```

The link from the email contains `token_hash` and `type=recovery`. Once the
handler exchanges it for a session, show a change password screen. The
`AccountManagement` contract does not include change password, so use the
Supabase gateway registered by the module:

```dart
final gateway = registry.read<SupabaseGateway>();
await gateway.updateUser(password: 'new-password');
```

For OAuth, call `SocialAuth.signIn(SocialProvider.google)`. The extension opens
the browser, waits for the session from the callback, and returns `null` if the
user cancels or the wait times out.

## 5. Observing callback failures

Failures that cannot be thrown to the caller are sent to
`SupabaseLinkHandler.failures`:

```dart
final handler = registry.read<SupabaseLinkHandler>();
handler.failures.listen((failure) {
  // failure.kind == FailureKind.authentication for Supabase errors
});
```

Links without auth parameters (for example ordinary links to an app page) are
ignored, so the `deep_link` extension can still use them for navigation.
