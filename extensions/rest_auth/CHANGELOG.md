# Changelog

## 0.1.1

- Bearer injection and 401 recovery are scoped to the configured backend
  origin and skip the credential endpoints.
- Refreshes no longer wait on themselves when they travel through the shared
  pipeline.
- Logout clears local credentials before any server revocation attempt.

## 0.1.0

- Initial release.
