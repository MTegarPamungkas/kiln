# Changelog

## 0.1.0

- Records are size-capped before every sink: message, error, stack trace and
  data strings respect `LoggerConfig.maxRecordTextLength` (16384 by default),
  and structured data is limited to 12 levels and 200 entries. The cap also
  applies when `redactionEnabled` is false.

- Initial release.
