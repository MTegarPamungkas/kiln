# Apple setup

## iOS and macOS

1. Enable the Sign in with Apple capability on the Runner target.
2. The extension adds the `com.apple.developer.applesignin` entitlement.
3. No service id is needed for native sign-in.

## Android and web

1. Create a Services ID in Apple Developer.
2. Register the redirect URI used by the app.
3. Fill in the prompt:

```bash
kiln config set apple_service_id=com.example.app.service
kiln config set apple_redirect_uri=https://example.com/callback
```

Without a service id and redirect, the Apple provider is hidden on Android and
the web. On iOS and macOS the provider remains available because it uses the
native dialog.

## Nonce

The random nonce is SHA-256 hashed before being sent to Apple. If the backend
checks the `nonce` claim, compare it with the hash of the original nonce that was
stored when the flow started; the extension does not store the original nonce.
