# Crash reporting

`crash_report` wires Sentry into the `kiln_core` `CrashReporter` contract. It
installs a decorator chain so that reporting is consent-gated, PII-redacted, and
failure-safe, and it forwards the logger's warning and error records as
breadcrumbs. The application owns every prompt and settings screen; the SDK only
sends data and returns results.

## Install

```sh
kiln add crash_report
```

The installer asks for a Sentry **DSN** and an optional **release**. An empty DSN
leaves the extension as a runtime no-op, so you can add it before the Sentry
project exists.

## Configuration

`CrashReportConfig` is rendered from the prompts and registered on the `Registry`:

| Field | Meaning |
| --- | --- |
| `dsn` | Sentry project DSN; empty disables reporting. |
| `release` | Optional release string used for grouping. |
| `environment` | Override; otherwise the installed `flavor` name is used. |
| `sampleRate` | Fraction of events actually sent (0.0–1.0). |
| `enabledFlavors` | Flavors allowed to send reports. |
| `sendDefaultPii` | Off by default; enabling lets Sentry attach device ids. |

## Gate usage

```dart
// Provided by kiln_core:
await gate.reportError(error, stackTrace: stackTrace, context: {'screen': 'home'});
await gate.reportMessage('Checkout failed');

// Provided by this extension:
await gate.reportBreadcrumb('Opened profile', data: {'tab': 'settings'});
await gate.setReportUser('user-1'); // null on sign-out
await gate.setReportContext('cart', {'items': 3});
final enabled = gate.crashReportsConsented;
```

## Support

`kiln doctor` marks the extension unsupported when the DSN is empty, the current
flavor is not enabled, or Sentry fails to initialize. A failed init is reported,
not thrown, so the app still boots.
