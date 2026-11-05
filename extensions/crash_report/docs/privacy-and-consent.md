# Privacy and consent

Crash reports carry stack traces, breadcrumbs, and free-form context, so they are
one of the most data-heavy signals an app can send. `crash_report` enforces two
independent layers before anything leaves the device.

## Consent gate

`ConsentGateCrashReporter` reads `ConsentController` on every call. Nothing is
sent until `ConsentCategory.crashReports` is granted:

- `captureError`, `captureMessage`, `addBreadcrumb`, and `setContext` are dropped
  before consent and start working the moment it is granted, with no restart.
- A non-null `setUser` identity is withheld before consent.
- `setUser(null)` is always forwarded, so signing out clears the Sentry user even
  if the user never opted in.

The application owns the consent UI; it calls `gate.consent.grant(ConsentCategory.crashReports)`
when the user agrees.

## PII redaction

`PiiScrubbingCrashReporter` runs every message, breadcrumb, and context map
through the shared `PiiRedactor`, which:

- masks values under known keys such as `password`, `token`, `secret`, `api_key`,
  `email`, and `phone`;
- strips bearer tokens, JWTs, and email addresses found in free text.

User ids are forwarded unchanged because they are pseudonymous grouping keys, not
profile data. `sendDefaultPii` stays off by default; turn it on only with your own
consent copy, because Sentry then attaches device identifiers.

## Breadcrumbs from the logger

The `logger` extension forwards warning and error records into the reporter.
Because the registered `CrashReporter` is already consent- and PII-wrapped, those
breadcrumbs inherit the same guarantees automatically — no logger-side changes
are needed.
