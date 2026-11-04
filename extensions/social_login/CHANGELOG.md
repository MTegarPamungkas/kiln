# Changelog

## 0.3.0

- Add `gate_social_login.dart` so the native `SocialLogin` service
  (`socialLoginSignIn`, `socialLoginSignOut`) is reachable through the `Gate`.
- Rewrite the credential and failure messages in English.

## 0.2.0

- Removed `SocialLoginButtons` and `SocialLoginPanel`. Applications call `SocialLogin` and render their own sign-in buttons.

## 0.1.1

- Add `SocialLoginSupport` with per-provider platform/configuration support.
- Report support through `SupportRegistry` and return
  `support.unsupported_platform` instead of `authProviderDisabled` on
  unsupported platforms.

## 0.1.0

- Initial Google and Apple credential login, nonce generation, availability,
  sign-out listener, and login widgets.
