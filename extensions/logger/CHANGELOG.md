# Changelog

## 0.3.0

- Add `gate_logger.dart` so the runtime log level (`logLevel`,
  `setLogLevel`) and the buffered records (`logRecords`, `clearLogs`) are
  reachable through the `Gate` facade.
- Fix a duplicated phrase in the README feature list.

## 0.2.0

- Removed `DebugLogPage`. Applications read log sinks and render their own log viewer.

## 0.1.1

- Add `LoggerSupport` with file-sink and sink configuration details.
- When file logging is unavailable, report the degradation while the console,
  memory, and breadcrumb sinks keep working.

## 0.1.0

- Added `LoggerModule` along with `AppLogger`, per-flavor level configuration,
  and runtime level control.
- Added a sink pipeline, text and JSON lines formatters, PII redaction, a memory
  buffer, rotating log files, and crash breadcrumbs.
- Added a log exporter, HTTP middleware, and a debug log page.
