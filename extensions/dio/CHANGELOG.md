# Changelog

## 0.1.3

- Import package:material_ui instead of the package:flutter/material.dart entry point, which Flutter 3.50 deprecated.

## 0.1.2

- Honour `HttpRequest.deadline`: reject expired requests before the transport,
  clamp connect/send/receive timeouts to the remaining time, and cancel Dio when
  the deadline passes with `network.deadline_exceeded`.

- Resolve the effective URL and default credentials before middleware runs,
  keeping cache policy consistent with the request sent on the wire.

- Return HTTP 304 responses from the Dio transport so the HTTP cache can
  complete revalidation instead of mapping a valid 304 to a failure.
- Return every received HTTP status to middleware and map only transport
  failures to `Failure`, so auth refresh, retry metadata, cache revalidation,
  and logging all see the real response.
- Pass a Dio `CancelToken` and the configured connect/receive timeouts to the
  transport; cancellation now aborts an in-flight request.
- The module closes the transport it owns on shutdown; an injected `Dio`
  remains owned by the caller.

## 0.1.1

- The API key is scoped to the configured `base_url` origin and is never sent to
  a third-party URL.
- Document cancellation, multipart upload, download, and API-key behavior.

## 0.1.0

- Initial release.
