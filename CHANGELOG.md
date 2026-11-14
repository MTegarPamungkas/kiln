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

## 0.1.0

- Initial release of the Kiln Flutter application framework: the `kiln_core`
  runtime with the one-call `Gate` `Result` facade, 33 app-owned extensions
  (including Sentry crash reporting behind a consent gate, json_serializable +
  freezed code generation, and vendor-neutral remote config / feature flags), the
  `kiln` CLI and extension registry, and CI including a version-drift guard.
