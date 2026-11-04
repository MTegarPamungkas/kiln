# Changelog

## 0.2.0

- Add `gate_deep_link.dart` so outgoing link building (`buildCustomLink`,
  `buildUniversalLink`) returns a `Result` instead of throwing.
- Rewrite the deep link failure messages in English.

## 0.1.2

- Probe the platform and capture the launch link during bootstrap through
  `DeviceDeepLinks.probeSupport`.
- Record an `unavailable` support state instead of silently ignoring a failed
  start.

## 0.1.1

- Register the custom URL scheme in `macos/Runner/Info.plist`, so the macOS
  target listed by the extension actually receives deep links.

## 0.1.0

- Initial deep link support: gateway `app_links`, allowlist, normalizer,
  deduplicator, pending link buffer, outgoing link builder, module, and tests.
