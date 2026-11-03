# Changelog

## 0.1.2

- Add `AppwriteSupport` for endpoint and identifier validation.
- Record a failed session restore as an `unavailable` support state instead of
  swallowing it.

## 0.1.1

- Sign-in now creates the email session over HTTP and forwards the session
  cookie as `X-Appwrite-Session`, so follow-up calls are authenticated even
  when the SDK cookie jar cannot persist cookies on plain HTTP endpoints.
- The session is restored on startup and persisted with `shared_preferences`;
  sign-out clears it. Adds `http` and `shared_preferences` dependencies.

## 0.1.0

- Initial Appwrite auth, account management, session bridge, query mapping,
  remote database, realtime gateway, and file storage.
