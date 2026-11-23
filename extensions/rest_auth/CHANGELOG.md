# Changelog

## 0.1.3

- Repack archive with deterministic cross-OS gzip and without root `test/`.

## 0.1.2

- A request deadline flows through `TokenProvider.accessToken` into the refresh
  `HttpRequest`, so the caller's total budget also covers the refresh. The first
  caller's deadline governs a shared in-flight refresh.
- The session bridge is disposed with the lifecycle and ignores a late
  `start()`, so a timed-out bootstrap cannot leave it mirroring into a closed
  `SessionController`.
- Guard cached-user restoration and credential writes across logout/disposal.
  Clear incomplete login writes and clear local state even when token reads fail.
- Declares the `token_provider` and `account_management` capabilities the module already registers, so `kiln doctor` capability coverage and backend-swap guidance see them.
- Serialize session changes so a delayed sign-in, reload, or refresh result
  cannot overwrite a newer login or clear a newer user.
- Scope stored tokens to the configured backend identity and discard tokens
  written by another backend.
- The runtime module now provides `token_provider` and `account_management`,
  matching the manifest.

## 0.1.1

- Bearer injection and 401 recovery are scoped to the configured backend
  origin and skip the credential endpoints.
- Refreshes no longer wait on themselves when they travel through the shared
  pipeline.
- Logout clears local credentials before any server revocation attempt.

## 0.1.0

- Initial release.
