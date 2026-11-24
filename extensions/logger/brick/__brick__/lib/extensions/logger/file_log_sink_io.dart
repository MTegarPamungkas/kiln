import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kiln_core/kiln_core.dart';
import 'package:path_provider/path_provider.dart';

import 'log_formatter.dart';
import 'log_sink.dart';

/// File logging is available on every platform with `dart:io`.
const bool fileLogSinkSupported = true;

/// Checks that the application documents directory is reachable.
Future<bool> probeFileLogSink() async {
  try {
    await getApplicationDocumentsDirectory();
    return true;
  } on Object {
    return false;
  }
}

/// Writes formatted records to a rotating file.
///
/// Files live in [directoryPath] when supplied, otherwise in a `logs` folder
/// under the application documents directory. When the current file would grow
/// past [maxFileBytes] it becomes `app.log.1`, older files shift up, and at most
/// [maxFiles] files are retained.
///
/// Records are buffered in memory up to [maxPending] entries and flushed to
/// disk in batches so bursts of logs do not open and close the file on every
/// record or grow the queue without bound. When the buffer is full the oldest
/// record is dropped and [droppedCount] is incremented.
///
/// This library is only selected on the Dart VM; the web build uses the stub.
final class FileLogSink implements LogSink {
  FileLogSink({
    this.directoryPath,
    this.fileName = 'app.log',
    this.maxFileBytes = 262144,
    this.maxFiles = 3,
    this.maxPending = 1000,
    this.formatter = const LogFormatter(),
    this.clock = const SystemClock(),
    this.onFailure,
  }) : assert(maxFileBytes > 0),
       assert(maxFiles > 0),
       assert(maxPending > 0);

  final String? directoryPath;
  final String fileName;
  final int maxFileBytes;
  final int maxFiles;
  final int maxPending;
  final LogFormatter formatter;
  final Clock clock;
  final SinkFailureWriter? onFailure;

  final ListQueue<List<int>> _buffer = ListQueue<List<int>>();
  Future<void>? _draining;
  Directory? _directory;
  int _currentSize = 0;
  bool _fileExists = false;
  int _droppedCount = 0;

  /// Number of records dropped because the pending buffer reached [maxPending].
  int get droppedCount => _droppedCount;

  /// Last failure reported by this sink, if any.
  Object? lastFailure;

  @override
  Future<void> write(LogRecord record) {
    final bytes = utf8.encode('${formatter.format(record)}\n');
    while (_buffer.length >= maxPending) {
      _buffer.removeFirst();
      _droppedCount++;
    }
    _buffer.addLast(bytes);
    return _ensureDraining();
  }

  @override
  Future<void> flush() async {
    final active = _draining;
    if (active != null) {
      await active;
    }
  }

  /// Reads every retained file from oldest to newest.
  Future<String> read() async {
    await flush();
    await _ensureDirectory();
    final directory = _directory;
    if (directory == null) {
      return '';
    }
    final buffer = StringBuffer();
    for (var index = maxFiles - 1; index >= 1; index--) {
      await _appendFile(buffer, _pathIn(directory, '$fileName.$index'));
    }
    await _appendFile(buffer, _pathIn(directory, fileName));
    return buffer.toString();
  }

  Future<void> _ensureDraining() {
    final existing = _draining;
    if (existing != null) {
      return existing;
    }
    late final Future<void> run;
    run = _drain().whenComplete(() {
      if (identical(_draining, run)) {
        _draining = null;
      }
      if (_buffer.isNotEmpty) {
        unawaited(_ensureDraining());
      }
    });
    _draining = run;
    return run;
  }

  Future<void> _drain() async {
    try {
      await _ensureDirectory();
      final directory = _directory;
      if (directory == null) {
        _buffer.clear();
        return;
      }
      final file = File(_pathIn(directory, fileName));
      while (_buffer.isNotEmpty) {
        final next = _buffer.first;
        if (_currentSize > 0 && _currentSize + next.length > maxFileBytes) {
          await _rotate(directory);
        }

        final batch = BytesBuilder(copy: false);
        var batchBytes = 0;
        if (!_fileExists) {
          final header = utf8.encode(
            '# started ${LogFormatter.timestamp(clock.now())}\n',
          );
          batch.add(header);
          batchBytes += header.length;
        }

        var entriesInBatch = 0;
        while (_buffer.isNotEmpty) {
          final entry = _buffer.first;
          final projected = _currentSize + batchBytes + entry.length;
          if (entriesInBatch > 0 && projected > maxFileBytes) {
            break;
          }
          if (_currentSize > 0 && projected > maxFileBytes) {
            break;
          }
          _buffer.removeFirst();
          batch.add(entry);
          batchBytes += entry.length;
          entriesInBatch++;
        }

        // If a single record is larger than maxFileBytes on a fresh file,
        // write it anyway so the queue always makes progress.
        if (entriesInBatch == 0 && _buffer.isNotEmpty) {
          final oversized = _buffer.removeFirst();
          batch.add(oversized);
          batchBytes += oversized.length;
        }

        if (batch.isNotEmpty) {
          final mode = _fileExists ? FileMode.append : FileMode.write;
          await file.writeAsBytes(
            batch.takeBytes(),
            mode: mode,
            flush: false,
          );
          _fileExists = true;
          _currentSize += batchBytes;
        }
      }
    } on Object catch (error, stackTrace) {
      // Drop queued entries from the failed drain cycle so a persistent I/O
      // failure cannot spin in an infinite retry loop.
      _buffer.clear();
      lastFailure = error;
      final writer = onFailure;
      if (writer != null) {
        try {
          writer(
            'FileLogSink could not append a log record.',
            error,
            stackTrace,
          );
        } on Object {
          // A broken failure writer must not stall the write queue.
        }
      }
    }
  }

  Future<void> _ensureDirectory() async {
    if (_directory != null) {
      return;
    }
    final Directory directory;
    final path = directoryPath;
    if (path != null) {
      directory = Directory(path);
    } else {
      final documents = await getApplicationDocumentsDirectory();
      directory = Directory('${documents.path}${Platform.pathSeparator}logs');
    }
    await directory.create(recursive: true);
    final current = File(_pathIn(directory, fileName));
    _fileExists = await current.exists();
    _currentSize = _fileExists ? await current.length() : 0;
    _directory = directory;
  }

  Future<void> _rotate(Directory directory) async {
    if (maxFiles <= 1) {
      final current = File(_pathIn(directory, fileName));
      if (await current.exists()) {
        await current.delete();
      }
      _currentSize = 0;
      _fileExists = false;
      return;
    }
    final oldest = File(_pathIn(directory, '$fileName.${maxFiles - 1}'));
    if (await oldest.exists()) {
      await oldest.delete();
    }
    for (var index = maxFiles - 2; index >= 1; index--) {
      final source = File(_pathIn(directory, '$fileName.$index'));
      if (await source.exists()) {
        await source.rename(_pathIn(directory, '$fileName.${index + 1}'));
      }
    }
    final current = File(_pathIn(directory, fileName));
    if (await current.exists()) {
      await current.rename(_pathIn(directory, '$fileName.1'));
    }
    _currentSize = 0;
    _fileExists = false;
  }

  Future<void> _appendFile(StringBuffer buffer, String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return;
    }
    final content = await file.readAsString();
    if (content.isEmpty) {
      return;
    }
    buffer.write(content);
    if (!content.endsWith('\n')) {
      buffer.writeln();
    }
  }

  String _pathIn(Directory directory, String name) {
    return '${directory.path}${Platform.pathSeparator}$name';
  }
}
