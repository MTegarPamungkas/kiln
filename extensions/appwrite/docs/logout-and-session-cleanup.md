# Logout and session cleanup

Logout must work offline. The Appwrite adapter treats server revocation as
best-effort and local credential removal as mandatory.

## What `signOut()` clears

`AppwriteAuth.signOut()` delegates to `SdkAppwriteAccount.signOut()` and always
clears the session bridge in a `finally` block.

The account adapter:

1. Marks the session as locally signed out.
2. Attempts `deleteSessions(current: true)`.
3. Clears the SDK session, cookie, JWT, and bearer values on the shared client
   and the account client.
4. Removes the persisted Appwrite cookie.
5. Persists a logout marker keyed by endpoint and project id.

A network error, timeout, or server 5xx during step 2 is ignored; the local
logout still completes. If local cleanup itself fails, the result is a
`Failure(unavailable, authentication)` with `localCleanupFailed: true`. The
application can surface that as a storage problem, not as "still signed in".

## Restore after logout

`currentUser()` and `restoreSession()` check the persisted logout marker before
using the SDK session. A stale cookie or SDK cookie jar must not revive the
previous account after a restart. Starting a new email/password sign-in or an
OAuth flow clears the marker.

## OAuth

`createOAuth2Session()` clears the marker before handing control to the Appwrite
OAuth redirect, because a new sign-in attempt overrides an earlier logout. After
the redirect completes, the normal session bridge publishes the new session.

## Test it offline

An adapter-level test should:

1. Create a session and persist the cookie.
2. Make `deleteSessions` fail with a network error.
3. Assert `signOut()` completes, the cookie is gone, the bridge is cleared, and
   `currentUser()` returns null.
4. Restart the adapter (fresh instance) and assert the old cookie is not
   restored.

Do not only test with a fake `AppwriteAccount`; that bypasses the transport and
cookie cleanup this extension exists to handle.
