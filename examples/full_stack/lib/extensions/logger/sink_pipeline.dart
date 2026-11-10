import 'dart:async';
import 'dart:developer' as developer;

import 'package:kiln_core/kiln_core.dart';

import 'log_level_controller.dart';
import 'log_sink.dart';

/// Sends every record to all attached sinks.
///
/// A sink that throws, synchronously or asynchronously, is reported through
/// [onFailure] and never stops the remaining sinks. Failures are never fed
/// back into this pipeline, which would risk an infinite loop.
final class SinkPipeline implements LogSink {
  SinkPipeline(Iterable<LogSink> sinks, {this.onFailure, this.enabled = true})
    : _sinks = List<LogSink>.of(sinks);

  final List<LogSink> _sinks;

  /// Receives sink failures; defaults to an isolated developer log entry.
  final SinkFailureWriter? onFailure;

  /// Whether records are forwarded at all.
  bool enabled;

  final Set<Future<void>> _inFlight = <Future<void>>{};

  /// Attached sinks in fan-out order.
  List<LogSink> get sinks => List<LogSink>.unmodifiable(_sinks);

  /// Adds a sink at the end of the fan-out order.
  void add(LogSink sink) => _sinks.add(sink);

  /// Removes a sink instance.
  bool remove(LogSink sink) => _sinks.remove(sink);

  @override
  FutureOr<void> write(LogRecord record) {
    if (!enabled) {
      return null;
    }
    for (final sink in List<LogSink>.of(_sinks)) {
      try {
        final result = sink.write(record);
        if (result is Future<void>) {
          _observe(sink, result);
        }
      } on Object catch (error, stackTrace) {
        _report(sink, error, stackTrace);
      }
    }
    return null;
  }

  @override
  Future<void> flush() async {
    while (_inFlight.isNotEmpty) {
      await Future.wait(_inFlight.toList(growable: false));
    }
    for (final sink in List<LogSink>.of(_sinks)) {
      try {
        await sink.flush();
      } on Object catch (error, stackTrace) {
        _report(sink, error, stackTrace);
      }
    }
  }

  void _observe(LogSink sink, Future<void> future) {
    final guarded = future.catchError((Object error, StackTrace stackTrace) {
      _report(sink, error, stackTrace);
    });
    late final Future<void> tracked;
    tracked = guarded.whenComplete(() => _inFlight.remove(tracked));
    _inFlight.add(tracked);
  }

  void _report(LogSink sink, Object error, StackTrace stackTrace) {
    final message =
        'Log sink ${sink.runtimeType} failed; other sinks keep receiving '
        'records.';
    final writer = onFailure;
    if (writer != null) {
      try {
        writer(message, error, stackTrace);
      } on Object catch (writerError, writerStackTrace) {
        developer.log(
          'The configured sink failure writer threw.',
          name: 'kiln.logger',
          error: writerError,
          stackTrace: writerStackTrace,
        );
      }
      return;
    }
    developer.log(
      message,
      name: 'kiln.logger',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// [AppLogger] that timestamps, filters, and forwards records to a pipeline.
final class PipelineLogger extends AppLogger {
  PipelineLogger({
    required this.pipeline,
    this.clock = const SystemClock(),
    this.levelController,
    this.minimumLevel = LogLevel.trace,
  });

  final SinkPipeline pipeline;
  final Clock clock;
  final LogLevelController? levelController;
  final LogLevel minimumLevel;

  /// Current threshold, read from the controller when one is attached.
  LogLevel get level => levelController?.level ?? minimumLevel;

  /// Whether a record at [level] would be forwarded.
  bool isEnabled(LogLevel level) => level.index >= this.level.index;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    if (!isEnabled(level)) {
      return;
    }
    final result = pipeline.write(
      LogRecord(
        level: level,
        message: message,
        timestamp: clock.now(),
        error: error,
        stackTrace: stackTrace,
        data: data,
      ),
    );
    if (result is Future<void>) {
      unawaited(result);
    }
  }

  /// Completes when every sink has flushed.
  Future<void> flush() => pipeline.flush();
}
