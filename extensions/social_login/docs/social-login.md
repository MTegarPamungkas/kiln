# Social login

`SocialLogin.signIn(provider)` returns a `SocialCredential` or null if the user
cancels. SDK failures are thrown as a `Failure`.

```dart
final login = registry.read<SocialLogin>();

final credential = await login.signIn(SocialProvider.google);
if (credential != null) {
  await backendSocialAuth.signInWithCredential(credential);
}
```

## Providers

- Google is available on Android, iOS, macOS, and the web. Fill in at least one
  client id: `google_server_client_id` for Android/web and
  `google_ios_client_id` for iOS/macOS.
- Apple is available natively on iOS and macOS. Android and the web require an
  `apple_service_id` and an `apple_redirect_uri` registered with Apple.

The application renders its own buttons, showing only providers that are
active, supported by the platform, and configured:

```dart
final login = registry.read<SocialLogin>();
final availability = registry.read<SocialAvailability>();

for (final provider in availability.providers) {
  FilledButton(
    onPressed: () => login.signIn(provider),
    child: Text(provider.label),
  );
}
```

## Nonce

Apple receives the SHA-256 hash of a random nonce. Store the original nonce only
if the server verifies the `nonce` claim in the identity token; this extension
does not store it.

## Sign out

If `AuthRepository` is installed, the module listens to `authStateChanges` and
calls `GoogleSignIn.signOut()` when the session becomes null. Apple has no SDK
session that needs to be cleared.
