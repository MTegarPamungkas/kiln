# social_login

Google and Apple sign-in paths that return `SocialCredential` for the
installed `SocialAuth` backend.

- The Google and Apple gateways can be faked in tests.
- `SocialLoginConfig` stores the client id and the active providers.
- `NonceGenerator` creates a random nonce and a SHA-256 hash for Apple.
- `SocialAvailability` filters providers by platform.
- `SocialSignOutListener` signs out the Google session when `AuthRepository`
  calls signOut.
- Applications render their own provider buttons and call `SocialLogin`.

Google setup: [docs/google-setup.md](docs/google-setup.md). Apple setup:
[docs/apple-setup.md](docs/apple-setup.md).

## Gate

```dart
final credential = await gate.socialSignIn(SocialProvider.google); // Result<SocialCredential?>
await gate.socialSignOut();
```

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
