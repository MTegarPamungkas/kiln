# Logout and session cleanup

Logout must work offline. The Appwrite adapter treats server revocation as
best-effort and local credential removal as mandatory.

## What `signOut()` clears

`AppwriteAuth.signOut()` clears application session state immediately, then
delegates to `SdkAppwriteAccount.signOut()`. Results from older restore and JWT
requests cannot repopulate that state after logout.

The account adapter:

1. Marks the session as locally signed out.
2. Attempts `deleteSessions(current: true)`.
3. Clears the SDK session, cookie, JWT, and bearer values on the shared client
   and the account client.
4. Removes the endpoint/project-scoped cookie, the obsolete global cookie key,
   and the SDK cookie jar entries it can access.
5. Persists a logout marker keyed by endpoint and project id.

A network error, timeout, or server 5xx during step 2 is ignored; the local
logout still completes. If local cleanup itself fails, the result is a
`Failure(unavailable, authentication)` with `localCleanupFailed: true`. The
application can surface that as a storage problem, not as "still signed in".

Email/password login, current-user restoration, JWT requests, and remote
revocation use a 15-second timeout per request by default. An account adapter's
`requestTimeout` can override it. Owned login HTTP clients are closed after
completion or timeout. Development builds follow the same self-signed
certificate policy as the SDK client; production keeps normal verification.

Email/password sign-in, restore, and sign-out are serialized within an adapter.
Logout invalidates a pending login, and delayed restore responses cannot clear
a newer session. JWT calls share one in-flight request per cache generation;
clearing the provider invalidates that request's result as well as the cache.

## Persistence and upgrades

The cookie key includes both the API endpoint and project ID. A stored cookie
for one configuration is never forwarded to another configuration. The legacy
global `kiln.appwrite.session.cookie` key is not restored, since its owner
cannot be identified. Existing installations may require another sign-in.

`AppwriteModule` uses the `SecureStorage` contract when the `secure_storage`
extension is installed. Otherwise Kiln's compatibility store uses plaintext
SharedPreferences. You can also inject an `AppwriteSessionStore` into the
account adapter for tests or an application-specific persistence policy.

The secure adapter preserves existing logout markers, avoids silently importing
plaintext cookies, and removes older preference copies when writing or deleting
the corresponding credentials. It does not silently downgrade to preferences
when secure storage fails.

This controls Kiln's copy of the cookie. Appwrite still manages its own native
or browser cookie jar, with its own persistence rules. Installing secure storage
does not establish that every vendor-managed credential is encrypted at rest.

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

The generated `appwrite_session_lifecycle_test.dart` exercises the account
adapter through Gate with deterministic HTTP responses, an SDK Account double,
and scoped persistence. It covers:

1. Create a session and persist the cookie.
2. Make `deleteSessions` fail with a network error.
3. Assert `signOut()` completes, the cookie is gone, the bridge is cleared, and
   `currentUser()` returns null.
4. Restart the adapter (fresh instance) and assert the old cookie is not
   restored.

It also covers combined Set-Cookie headers, request timeouts, rejected sessions,
failed local cleanup, secure-store migration markers, and delayed restore/JWT
results. These tests exercise the adapter; they do not contact a real server or
verify device plugins, browser OAuth, or background delivery. Run the opt-in
live e2e suite and device tests for those integrations.
