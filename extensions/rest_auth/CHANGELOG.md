# Changelog

## 0.1.2

- Declares the `token_provider` and `account_management` capabilities the module already registers, so `kiln doctor` capability coverage and backend-swap guidance see them.

## 0.1.1

- Bearer injection and 401 recovery are scoped to the configured backend
  origin and skip the credential endpoints.
- Refreshes no longer wait on themselves when they travel through the shared
  pipeline.
- Logout clears local credentials before any server revocation attempt.

## 0.1.0

- Initial release.
