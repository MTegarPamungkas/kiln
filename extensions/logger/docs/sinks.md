# Sinks

A sink is the final destination of a `LogRecord`. The contract is small:

```dart
abstract interface class LogSink {
  FutureOr<void> write(LogRecord record);
  FutureOr<void> flush();
}
```

`SinkPipeline` sends every record to all sinks in order. A sink that throws an
error, whether synchronous or asynchronous, is reported through `onFailure` and
does not stop the next sink. Do not log sink failures through the same pipeline;
use a fallback writer so that recursion does not occur.

Custom sink:

```dart
final class HttpCollectorSink implements LogSink {
  HttpCollectorSink(this.client);

  final HttpClient client;
  final List<LogRecord> buffer = <LogRecord>[];

  @override
  FutureOr<void> write(LogRecord record) {
    buffer.add(record);
    return null;
  }

  @override
  Future<void> flush() async {
    if (buffer.isEmpty) return;
    // Send the buffer to the backend, then clear it.
  }
}
```

## Decorator order

Wrap a sink in `RedactingSink` before that sink stores or sends personal data.
The recommended order:

```text
PipelineLogger -> SinkPipeline -> RedactingSink -> MemoryLogSink
                                              -> FileLogSink
                                              -> BreadcrumbSink
```

The module already does this for all sinks when `redactionEnabled` is true.
`LogExporter` redacts again when reading, so reports stay safe even if old
records came from another sink.

## Implementation notes

- Write records serially when a sink has state, such as a rotating file.
- `flush()` must wait for all writes that have already been accepted.
- Do not block the caller of `write()` with long network work; queue it and
  finish it in `flush()`.
- `MemoryLogSink` uses a ring buffer: fixed capacity and the oldest records are
  discarded first.
