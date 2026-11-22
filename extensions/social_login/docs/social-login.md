# Social login

`SocialLogin.signIn(provider)` returns a `SocialCredential` or null if the user
cancels. SDK failures are thrown as a `Failure`.

```dart
final login = registry.read<SocialLogin>();

final credential = await login.signIn(SocialProvider.google);
if (credential != null) {
  // Send the provider credential to your backend exchange endpoint:
  // credential.idToken, rawNonce, authorizationCode, accessToken.
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

## Nonce and code

Apple receives the SHA-256 hash of a random nonce. The original nonce is
returned as `credential.rawNonce`, and Apple's authorization code is returned as
`credential.authorizationCode`; forward both to the backend so it can verify the
`nonce` claim and exchange the code when its flow requires it. `accessToken`
stays reserved for provider access tokens.

## Audience

Credentials from this extension use
`SocialTokenAudience.provider`. A backend adapter that already created its own
session (Appwrite, Supabase OAuth, Firebase) returns
`SocialTokenAudience.backend` and exposes that token in
`backendSessionToken`; never forward such a token to another backend as a
provider identity token.

## Sign out

If `AuthRepository` is installed, the module listens to `authStateChanges` and
calls `GoogleSignIn.signOut()` when the session becomes null. Apple has no SDK
session that needs to be cleared.
