# analytics

An implementation of `Analytics` from `kiln_core` on top of PostHog.

- Events and identities are only sent after the `analytics` category on
  `ConsentController` is granted.
- Properties are sanitized into JSON-like values, then redacted with
  `PiiRedactor` before touching the SDK.
- `SessionIdentityListener` calls `identify` on sign-in and `reset` on sign-out,
  following `SessionController`.
- If the API key is empty or the current flavor is not allowed, the module uses
  `NoopAnalytics` so application code can still safely call analytics.
- All SDK access sits behind `AnalyticsGateway`, so tests touch neither the
  plugin nor the network.

Install this extension together with the analytics module in the app's module
list, then read [docs/analytics.md](docs/analytics.md) for configuration and
usage.
