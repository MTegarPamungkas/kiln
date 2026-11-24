# Changelog

## 0.1.2

- Buffer and batch writes in `FileLogSink` with a bounded pending queue
  (`maxPending`, drop-oldest, and `droppedCount`).
- Snapshot in-flight writes in `SinkPipeline.flush()` so continuous logging
  cannot starve flush completion.

## 0.1.1

- Await `FutureOr<void>` sink `write` calls in logger brick tests to satisfy `unawaited_futures`.

## 0.1.0

- Records are size-capped before every sink: message, error, stack trace and
  data strings respect `LoggerConfig.maxRecordTextLength` (16384 by default),
  and structured data is limited to 12 levels and 200 entries. The cap also
  applies when `redactionEnabled` is false.

- Initial release.
