# Changelog

All notable changes to the Kiln SDK are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Individual packages and extensions keep their own `CHANGELOG.md`; this file
records release-level changes for the monorepo.

## Unreleased

- New `appwrite_push_native` extension 0.1.0: a `push_transport` over Appwrite
  Push (MQTT subscriptions) with no Firebase project or device token. It follows
  the signed-in session, re-subscribes when the user changes, replays the launch
  tap, reports subscribe failures, and supports self-hosted broker endpoints.
- The `appwrite` extension 0.3.1 registers its configured `appwrite.Client` so
  sibling transports subscribe on the same signed-in session, and decodes the
  URL-encoded session cookie Appwrite 2.7+ returns.
- `kiln doctor` reports capability coverage: feature code that references a
  backend capability no installed extension provides (for example
  `CloudFunctions` after swapping from Appwrite to Supabase) now produces a
  warning with remediation guidance.
- The Appwrite extension 0.2.0 adds a `functions` capability implementing the
  new `CloudFunctions` contract (`Functions.createExecution`), with live e2e
  coverage against a deployed function.

### Fixed

- Release archives include the workspace root and the release workflow verifies
  the extracted CLI and scaffolds a standalone test app.
- The README count tracks the 34 active extensions. The registry checks archive
  references and retains the historical Neon archive explicitly.

- Codegen installs both json_serializable and Freezed. The wizard removes
  the generator picker because it did not change the generated setup.
- Remote config uses caller fallbacks for invalid boolean values and refreshes
  on resume after the configured interval. Apps can opt out with
  `refreshOnResume: false`.
- Geolocation maps service, permission, timeout, and stream errors to typed
  failures and rejects negative distance filters.
- HTTP logging strips URL fragments before applying the configured redaction.
- Theme and locale serialize preference writes and report whether the selected
  value was persisted. The selection still applies for the current session.

### Removed

- The active catalog drops Neon. Existing archived artifacts retain their
  historical paths.

### Verification

- Manifest metadata is checked against module declarations. A rendered
  27-module fixture exercises dependency ordering and registration.
  [Composition evidence](docs/audit/evidence/composed-fixture-2026-11-21.md)
- The Supabase adapter passed same-project RLS and browser OAuth checks. Its
  signed URLs were verified on a local Storage service.
  [RLS and OAuth](docs/audit/supabase-local-rls-2026-11-22.md)
  · [Signed URLs](docs/audit/supabase-signed-urls-2026-11-22.md)

## 0.1.0

- Initial release of the Kiln Flutter application framework: the `kiln_core`
  runtime with the one-call `Gate` `Result` facade, 33 app-owned extensions
  (including Sentry crash reporting behind a consent gate, json_serializable +
  freezed code generation, and vendor-neutral remote config / feature flags), the
  `kiln` CLI and extension registry, and CI including a version-drift guard.
