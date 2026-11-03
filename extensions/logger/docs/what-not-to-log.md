# What not to log

Logs are often sent to crash reporters, shared through bug reports, or stored on
the device. Treat every log line as data that other people can read.

## Never log

- Passwords, PINs, OTPs, and security question answers.
- Access tokens, refresh tokens, API keys, and server secrets.
- `Authorization` headers, session cookies, and other authentication headers.
- Card numbers, CVVs, account numbers, and payment data.
- Request or response bodies that contain personal data.
- Documents, photos, or the contents of user messages.

## Be careful

- Email, phone numbers, national ID numbers, and addresses: use an internal id
  when possible.
- URLs: queries often contain tokens; the middleware strips the query before
  logging.
- Server errors: raw messages can contain payloads. Log the code and status, not
  the response body.
- Stack traces: useful for reproduction, but do not add input values to them.

## Built-in protection

- `RedactingSink` redacts messages, data, and error text with `PiiRedactor`
  before records reach a sink.
- `HttpLogMiddleware` redacts headers and never logs bodies.
- `LogExporter` redacts again when combining reports.
- `BreadcrumbSink` only forwards warnings and errors, and receives records that
  have already been redacted by the pipeline.

Redaction is the last line of defense, not permission to log secrets. If a value
is not needed to diagnose a problem, do not put it in `LogRecord.data`.
