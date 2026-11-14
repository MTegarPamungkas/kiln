# Changelog

## 0.1.0

- Initial release. Implements the `push_transport` capability over Appwrite
  Push: subscribes to the signed-in user's topic through the Appwrite SDK,
  streams foreground envelopes, and exposes background notification taps.
- Re-subscribes when a different user signs in on the same client, replays the
  launch tap to the first `opened` listener, and reports subscribe failures on
  `errors`/`lastError`.
