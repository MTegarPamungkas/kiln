# Changelog

## 0.1.3

- Rewrite the REST auth failure, response, and endpoint messages in English.

## 0.1.2

- Validate the REST auth base URL and endpoint paths through
  `RestAuthSupport`.
- Probe secure storage during bootstrap and record session restore failures as
  `unavailable`.

## 0.1.1

- Configuration test now renders the prompt answers instead of hardcoded
  defaults, so regenerated apps keep passing `flutter test`.

## 0.1.0

- Initial REST AuthRepository, token store, single-flight refresh, JWT expiry,
  middleware, unauthorized handling, account management, and session bridge.
