# logger

Implementation of `AppLogger` from `kiln_core`: leveled logging, composable
sinks, personal data redaction, rotating log files, an in-memory buffer, crash
breadcrumbs, and HTTP request logging.

- `LoggerModule` registers `AppLogger`, `LoggerConfig`, `LogLevelController`,
  `MemoryLogSink`, and `FileLogSink` when the file sink is active.
- Levels follow the flavor: `development` (trace), `staging` (debug), and
  `production` (warning). Without the `flavor` extension, debug builds use the
  development level and release builds use the production level.
- `RedactingSink` redacts messages, data, and error text with `PiiRedactor`
  before they reach a sink.
- `HttpLogMiddleware` logs the method, URL without query, status, and duration;
  the `Authorization` header is redacted and bodies are never logged.
- Applications read `MemoryLogSink` and render their own log viewer.

```dart
final logger = registry.read<AppLogger>();
logger.info('checkout complete', data: {'order': 42});
```

Read [docs/logging.md](docs/logging.md) for usage guidance,
[docs/sinks.md](docs/sinks.md) for writing your own sink, and
[docs/what-not-to-log.md](docs/what-not-to-log.md) for the list of data that must
not be logged.

## Gate

```dart
gate.logger.info('User signed in', data: {'id': userId});
gate.logger.error('Upload failed', error: err);

final level = gate.logLevel;              // LogLevel
await gate.setLogLevel(LogLevel.debug);   // Result<void> (Err in production)
final records = gate.logRecords;          // List<LogRecord>
gate.clearLogs();                         // empties the buffer
```

Synchronous access through the facade.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
