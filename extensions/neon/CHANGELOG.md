# Changelog

## 0.1.1

- Object Storage now uses a JWT-authenticated signing backend; the app never
  ships an S3 access key or secret.
- Same-column query filters are preserved, and `in`/`not.in` use PostgREST's
  list grammar.
- Gateways close only the clients they own.

## 0.1.0

- Initial release.
