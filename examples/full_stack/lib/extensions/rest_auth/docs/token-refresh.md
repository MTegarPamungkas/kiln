# Token refresh

## When to refresh

`TokenRefresher` uses two sources of expiry:

1. `expiresAt` from the login response (computed from `expires_in` or
   `expiresAt`).
2. The JWT `exp` if the server does not send a validity period.

A token is considered to need a refresh when less than 30 seconds remain
(leeway `RestAuthConfig.refreshLeeway`).

## Single-flight

All callers of `accessToken()` that find an expired token share a single refresh
`Future`. The server receives only one refresh request even when ten HTTP
requests are running concurrently.

```dart
final token = await auth.tokenProvider.accessToken();
```

When the caller has a request deadline, `accessToken(deadline: ...)` and
`refreshAccessToken(deadline: ...)` pass it through to the refresh `HttpRequest`,
so the caller's total budget covers the refresh too. The first caller's deadline
governs a shared in-flight refresh; a later caller joins it rather than
shortening it.

## After a 401

`UnauthorizedHandler` does the following:

1. Calls `refreshAccessToken()`.
2. If a new token exists, retries the request once with the new Bearer.
3. If the refresh fails or the second request is still 401, calls
   `clearSession()`.

`clearSession()` deletes local tokens, cached user state, and marks the session
as ended without making another network request, so navigation guards can send
the user to the sign-in page. The public `signOut()` clears local state first,
then attempts the logout endpoint with the token captured before clearing; a
slow or offline server cannot keep the user signed in.

Session changes are serialized. A sign-in, sign-up, reload, or refresh result
that completes after a newer session operation is discarded with
`auth.cancelled` instead of writing old credentials or clearing a new user. Only
the session that issued a refresh may be cleared by a 401/403 refresh rejection.

## Failures

A failed refresh throws a `Failure` mapped from the server status. A dropped
connection does not delete the tokens; the user can try again when online. A
storage failure during local sign-out is rethrown after the session is marked as
ended.
