# Changelog

## 0.1.0

- The link handler and session bridge are disposed with the lifecycle and
  ignore a late `start()`; disposal during the initial callback no longer leaves
  a `DeepLinks` listener behind or delivers a session to a closed app.
- Accept env:NAME references for the publishable client key without saving
  its resolved value in setup answers or generated source.
- Initial release.
- Auth operations use a generation and commit boundary: a delayed restore,
  sign-in, or sign-up cannot overwrite a newer session, and sign-out clears
  local state before the remote revoke (offline sign-out still works).
- The browser OAuth flow ignores a session that existed before the launch.
- Social results mark the Supabase session as a backend token and keep it out of
  `accessToken`; a new `credentialSource` forwards the raw nonce and provider
  authorization code to `signInWithIdToken`.
