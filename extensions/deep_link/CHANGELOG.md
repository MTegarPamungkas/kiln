# Changelog

## 0.1.2

- Update the rendered config golden for the custom-scheme host settings added in
  the previous release.

## 0.1.1

- Apply route prefixes to custom links, add separate custom-scheme host
  restrictions and reject unsafe/encoded traversal paths.

- The native Android, iOS, and macOS URL scheme now follows the `scheme`
  prompt through `url_scheme_prompt`, instead of staying on `kiln`.
- The module disposes its device link subscription and stream on shutdown.

## 0.1.0

- Initial release.
