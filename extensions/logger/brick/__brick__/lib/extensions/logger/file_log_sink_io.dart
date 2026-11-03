import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kiln_core/kiln_core.dart';
import 'package:path_provider/path_provider.dart';

import 'log_formatter.dart';
import 'log_sink.dart';

/// File logging is available on every platform with `dart:io`.
const bool fileLogSinkSupported = true;

/// Writes formatted records to a rotating file.
///
/// Files live in [directoryPath] when supplied, otherwise in a `logs` folder
/// under the application documents directory. When the current file would grow
/// past [maxFileBytes] it becomes `app.log.1`, older files shift up, and at most
/// [maxFiles] files are retained. Writes are serialized so rotation never
/// interleaves with an append.
///
/// This library is only selected on the Dart VM; the web build uses the stub.
final class FileLogSink implements LogSink {
  FileLogSink({
    this.directoryPath,
    this.fileName = 'app.log',
    this.maxFileBytes = 262144,
    this.maxFiles = 3,
    this.formatter = const LogFormatter(),
    this.clock = const SystemClock(),
    this.onFailure,
  }) : assert(maxFileBytes > 0),
       assert(maxFiles > 0);

  final String? directoryPath;
  final String fileName;
  final int maxFileBytes;
  final int maxFiles;
  final LogFormatter formatter;
  final Clock clock;
  final SinkFailureWriter? onFailure;

  Future<void> _pending = Future<void>.value();
  Directory? _directory;
  int _currentSize = 0;

  /// Last failure reported by this sink, if any.
  Object? lastFailure;

  @override
  Future<void> write(LogRecord record) {
    final bytes = utf8.encode('${formatter.format(record)}\n');
    return _enqueue(() async {
      await _ensureDirectory();
      final directory = _directory;
      if (directory == null) {
        return;
      }
      if (_currentSize > 0 && _currentSize + bytes.length > maxFileBytes) {
        await _rotate(directory);
      }
      final file = File(_pathIn(directory, fileName));
      if (!await file.exists()) {
        final header = utf8.encode(
          '# started ${LogFormatter.timestamp(clock.now())}\n',
        );
        await file.writeAsBytes(header, flush: false);
        _currentSize = header.length;
      }
      await file.writeAsBytes(bytes, mode: FileMode.append, flush: false);
      _currentSize += bytes.length;
    });
  }

  @override
  Future<void> flush() async {
    await _pending;
  }

  /// Reads every retained file from oldest to newest.
  Future<String> read() async {
    await _pending;
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

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _pending.then((_) => action());
    _pending = next.catchError((Object error, StackTrace stackTrace) {
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
    });
    return _pending;
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
      directory = Directory(
        '${documents.path}${Platform.pathSeparator}logs',
      );
    }
    await directory.create(recursive: true);
    final current = File(_pathIn(directory, fileName));
    _currentSize = await current.exists() ? await current.length() : 0;
    _directory = directory;
  }

  Future<void> _rotate(Directory directory) async {
    if (maxFiles <= 1) {
      final current = File(_pathIn(directory, fileName));
      if (await current.exists()) {
        await current.delete();
      }
      _currentSize = 0;
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
