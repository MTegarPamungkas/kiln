# Changelog

## 0.1.0

- The sign-out listener is disposed with the lifecycle and ignores a late
  `start()`, so it cannot sign out of Google after the application shut down.
- Initial release.
- The runtime module mirrors the manifest's Android/iOS/macOS/web platform list.
- Apple credentials now return the raw nonce and the authorization code as
  dedicated fields instead of overloading the provider access token.
