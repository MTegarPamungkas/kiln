# Changelog

All notable changes to the Kiln SDK are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Individual packages and extensions keep their own `CHANGELOG.md`; this file
records release-level changes for the monorepo.

## 0.1.0

- Initial release of the Kiln Flutter application framework: the `kiln_core`
  runtime with the one-call `Gate` `Result` facade, 30 app-owned extensions
  (including Sentry crash reporting behind a consent gate), the `kiln` CLI and
  extension registry, and CI including a version-drift guard.
