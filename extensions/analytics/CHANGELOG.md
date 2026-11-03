# Changelog

## 0.1.1

- Add `AnalyticsSupport` with API key, host, flavor, and setup checks.
- Report disabled analytics as `notConfigured` and setup failures as
  `unavailable` through `SupportRegistry`.

## 0.1.0

- Initial PostHog gateway, typed config, event, and property sanitizer.
- Consent gate, PII scrubbing, and noop decorators.
- Session identity listener and module wiring with best-effort setup.
