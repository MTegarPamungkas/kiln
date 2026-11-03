# Logging

`AppLogger` is a contract from `kiln_core`. This extension provides its
implementation through `PipelineLogger`, which adds timestamps, filters by
level, and then forwards `LogRecord` values to the `SinkPipeline`.

```dart
final logger = registry.read<AppLogger>();

logger.debug('loading profile');
logger.info('profile loaded', data: {'user': 'u-1'});
logger.warning('stale cache used');
logger.error('sync failed', error: failure, stackTrace: stack);
```

## Levels

| Flavor | Default level |
| --- | --- |
| `development` | `trace` |
| `staging` | `debug` |
| `production` | `warning` |

These values come from `LoggerConfig`. If the `flavor` extension is not
installed, the module uses development for debug builds and production for
release builds.

`LogLevelController` can be changed at runtime only in non-production flavors.
In production, `setLevel` throws a `Failure` with the code
`validation.unsupported_value`; the configured level remains in use.

```dart
final levels = registry.read<LogLevelController>();
levels.setLevel(LogLevel.trace); // non-production only
```

## Sinks

The active sinks are controlled by `LoggerConfig.activeSinks`:

- `console` prints a single line of text.
- `memory` keeps the last N records for bug reports and tests.
- `file` writes to a rotating `app.log` in the app documents `logs` folder.
- `breadcrumb` forwards warnings and errors to `CrashReporter`.

The file sink is only available on the VM. Web builds use a stub, so importing
`file_log_sink.dart` is safe on all platforms.

## HTTP

If the `http_logging` prompt is active and `HttpPipeline` is registered,
`HttpLogMiddleware` is added with priority 90. The middleware records the
method, URL without query and user info, status, and duration. Headers are
redacted with `PiiRedactor`; bodies are never logged. 4xx responses are logged
as warnings, 5xx and network errors as errors, and errors are still rethrown.

## Debug and export

Applications render their own log viewer from `MemoryLogSink`; the extension
does not ship a page.

```dart
final exporter = LogExporter(
  memory: registry.read<MemoryLogSink>(),
  file: registry.isRegistered<FileLogSink>()
      ? registry.read<FileLogSink>()
      : null,
);
final report = await exporter.export();
```

The report combines memory records and file contents, then redacts both again
before they are displayed or shared.
