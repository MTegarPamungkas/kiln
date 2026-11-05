# Crash Report

Sentry crash reporting for Kiln. It implements the `kiln_core` `CrashReporter`
contract over [`sentry_flutter`](https://pub.dev/packages/sentry_flutter) and
layers a consent gate, PII redaction, and a failure-safe decorator so a broken
reporter can never take down the app. The application owns every screen; this
extension only ships the gateway, configuration, and the wiring.

## Install

```sh
kiln add crash_report
```

The installer prompts for a Sentry **DSN** and an optional **release**. Leave the
DSN empty and the extension becomes a no-op at runtime, so you can add it before
you have a Sentry project.

## Configuration

`CrashReportConfig` is generated from the prompts and read from the registry:

- `dsn` — Sentry project DSN. An empty DSN disables reporting.
- `release` — optional release string used for grouping.
- `environment` — derived from the installed `flavor` extension (`development`,
  `staging`, `production`).
- `sampleRate` — how many events to actually send.
- `enabledFlavors` — flavors allowed to leave the device.
- `sendDefaultPii` — defaults to `false`; enabling it lets Sentry attach device
  identifiers, so pair it with your own consent copy.

## Gate usage

`kiln_core` already exposes the reporting verbs; this extension adds the rest of
the contract as single-call `Result` verbs:

```dart
// From kiln_core:
await gate.reportError(error, stackTrace: stackTrace, context: {'screen': 'home'});
await gate.reportMessage('Checkout failed');

// From gate_crash_report.dart:
await gate.reportBreadcrumb('Opened profile', data: {'tab': 'settings'});
await gate.setReportUser('user-1'); // null on sign-out
await gate.setReportContext('cart', {'items': 3});
final enabled = gate.crashReportsConsented;
```

## Consent and privacy

`ConsentGateCrashReporter` reads `ConsentController` on every call. Nothing is
sent to Sentry until `ConsentCategory.crashReports` is granted; `captureError`,
`captureMessage`, and `addBreadcrumb` are dropped before that. Identity is the
exception: `setUser` is always forwarded so a sign-out clears the Sentry user,
but a non-null user id is only attached once consent exists.

`PiiScrubbingCrashReporter` runs every message, breadcrumb, context map, and
user id through the shared `PiiRedactor`, which masks known keys (password,
token, email, phone, and similar) plus bearer tokens, JWTs, and email patterns.

## Breadcrumbs from the logger

When the `logger` extension is installed, its `BreadcrumbSink` forwards warning
and error records into this reporter as breadcrumbs — and because the registered
`CrashReporter` is already consent- and PII-wrapped, those breadcrumbs respect
the same rules for free.

## Reliability

Two decorators keep reporting safe under load:

- **Error deduplication** — `ErrorDeduplicator` collapses repeated identical
  errors (same runtime type and message) into one report within
  `CrashReportConfig.dedupWindow` (default 60s), using the shared `Clock` so it
  is deterministic in tests. Disable with `dedupEnabled: false`.
- **HTTP breadcrumbs** — when the `http_pipeline` capability is present (the
  `dio` extension), `HttpBreadcrumbMiddleware` records one breadcrumb per
  exchange (method, sanitized URL, status, duration) at pipeline priority 95.
  It never captures request bodies or headers, and the URL drops the query
  string. Toggle with `httpBreadcrumbsEnabled`.

Because the registered `CrashReporter` is the full `Safe → Consent → PII →
Dedup → vendor` chain, both features inherit consent gating and redaction.

## Support

`kiln doctor` reports the extension as unsupported when the DSN is empty or the
current flavor is not enabled, and when Sentry fails to initialize; a failed
init is mapped to a `Failure(unavailable)` so the app still starts.
