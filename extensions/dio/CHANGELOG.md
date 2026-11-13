# Changelog

## 0.1.2

- Return HTTP 304 responses from the Dio transport so the HTTP cache can
  complete revalidation instead of mapping a valid 304 to a failure.

## 0.1.1

- The API key is scoped to the configured `base_url` origin and is never sent to
  a third-party URL.
- Document cancellation, multipart upload, download, and API-key behavior.

## 0.1.0

- Initial release.
