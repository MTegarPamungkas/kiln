# Changelog

## 0.2.3

- Add API-key support through `--dart-define=KILN_API_KEY`, sent as a header or
  query parameter configured by prompts.
- Keep a truncated server message in `Failure.details['serverMessage']` for
  4xx/5xx responses.
- Map 404 to `unavailable`, 408 to `networkTimeout`, and 429 to a retryable
  `networkServer` failure with `retryAfterSeconds` when provided.

## 0.2.2

- Resolve relative request URIs against `DioConfig.baseUrl`; previously the
  configured base URL was ignored and relative paths reached the adapter
  unresolved.

## 0.2.1

- Dio failures are mapped to `Failure` inside the transport handler, so
  pipeline middleware such as `http_retry` can retry 5xx responses.

## 0.2.0

- Add typed configuration and pipeline middleware.
- Add request id and user agent interceptors.

## 0.1.0

- Initial release.
