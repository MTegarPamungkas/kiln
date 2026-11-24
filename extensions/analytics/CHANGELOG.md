# Changelog

## 0.1.2

- Update `posthog_flutter` dependency constraint to `^6.0.0`.

## 0.1.1

- Update the rendered config golden for the session-identity and consent
  settings added in the previous release.

## 0.1.0

- A consent revoke no longer leaves traffic behind: the SDK sends one event per
  batch (`flushAt: 1`) so nothing sits queued across a consent change, the
  identity rotation moves to the next grant instead of revoke (no `/flags/`
  reload after consent ends), and every grant opts in so a persisted opt-out
  cannot outlive the consent that replaced it.

- Clean up late SDK initialization after disposal, stop disposed reporters
  forwarding events and support env:NAME build-variable client keys.

- Initial release.
- PostHog is initialized only after analytics consent is granted. A consent
  grant starts or re-enables the SDK and identifies the current session; a
  revocation opts out, clears identity, and reports "waiting for consent".
  A transport-level consent filter drops events if consent disappears.
- The raw `AnalyticsGateway` and `PosthogAnalytics` are no longer registered as
  services, so callers cannot bypass the consent and PII decorators.
- Shutdown awaits queued identity work and flushes the SDK it started.
