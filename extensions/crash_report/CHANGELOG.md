# Changelog

## 0.1.1

- Await `Sentry.configureScope` calls in `SentryCrashGateway.setUser` and `setContext` to satisfy `unawaited_futures`.

## 0.1.0

- Close late SDK initialization after disposal, stop disposed reporters
  forwarding events and support env:NAME build-variable DSNs.

- Initial release.
- Sentry is initialized only after crash-report consent is granted. A
  revocation clears the Sentry user and a `beforeSend` consent filter drops
  queued or automatic events; a later grant retries initialization.
- The raw `CrashReportGateway` and `SentryCrashReporter` are no longer
  registered as services, so callers cannot bypass the consent and redaction
  decorators.
