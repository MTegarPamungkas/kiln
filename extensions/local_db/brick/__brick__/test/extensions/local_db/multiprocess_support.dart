import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kiln_core/kiln_core.dart';

/// Shared helpers for the multi-process tests.
///
/// These tests spawn a second real Dart process instead of simulating one with
/// an isolate or a fake: POSIX `fcntl` locks are owned by the process, so only a
/// separate process can prove that a competing writer waits and that the
/// operating system releases the lock when that process dies.

String? _dartExecutable;

String _join(List<String> parts) => parts.join(Platform.pathSeparator);

/// Absolute Dart executable when it can be found, otherwise `dart` on `PATH`.
String resolveDartExecutable() {
  final cached = _dartExecutable;
  if (cached != null) {
    return cached;
  }
  final override = Platform.environment['KILN_DART'];
  if (override != null && override.isNotEmpty && File(override).existsSync()) {
    return _dartExecutable = override;
  }
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null && root.isNotEmpty) {
    final candidate = File(
      _join(<String>[
        root,
        'bin',
        'cache',
        'dart-sdk',
        'bin',
        Platform.isWindows ? 'dart.exe' : 'dart',
      ]),
    );
    if (candidate.existsSync()) {
      return _dartExecutable = candidate.path;
    }
  }
  var directory = File(Platform.resolvedExecutable).parent;
  for (var depth = 0; depth < 8; depth++) {
    final candidate = File(
      _join(<String>[
        directory.path,
        'cache',
        'dart-sdk',
        'bin',
        Platform.isWindows ? 'dart.exe' : 'dart',
      ]),
    );
    if (candidate.existsSync()) {
      return _dartExecutable = candidate.path;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      break;
    }
    directory = parent;
  }
  return _dartExecutable = 'dart';
}

/// A worker process started from a test, with line-oriented stdout inspection.
final class DartWorker {
  DartWorker._(this._process) {
    final drained = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          _lines.add(line);
          _wake();
        })
        .asFuture<void>()
        .then<Object?>((_) => null);
    _process.stderr.transform(utf8.decoder).listen(_stderr.write);
    _exit = Future.wait<Object?>(<Future<Object?>>[_process.exitCode, drained])
        .then((values) {
          final code = values.first! as int;
          _exitCode = code;
          _wake();
          return code;
        });
  }

  final Process _process;
  final List<String> _lines = <String>[];
  final StringBuffer _stderr = StringBuffer();
  final List<Completer<void>> _waiters = <Completer<void>>[];
  late final Future<int> _exit;
  int? _exitCode;

  /// Starts [script] with the rendered application's package config.
  static Future<DartWorker> start(
    String script,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    final dart = resolveDartExecutable();
    final process = await Process.start(
      dart,
      <String>[
        '--packages=.dart_tool/package_config.json',
        script,
        ...arguments,
      ],
      workingDirectory: workingDirectory ?? Directory.current.path,
      runInShell: dart == 'dart' && Platform.isWindows,
    );
    return DartWorker._(process);
  }

  List<String> get stdoutLines => List<String>.unmodifiable(_lines);

  String get stderrText => _stderr.toString();

  bool get hasExited => _exitCode != null;

  Future<int> get exitCode => _exit;

  /// Waits until a stdout line contains [needle].
  Future<String> waitForLine(
    String needle, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      for (final line in _lines) {
        if (line.contains(needle)) {
          return line;
        }
      }
      final code = _exitCode;
      if (code != null) {
        throw StateError(
          'Worker exited ($code) before "$needle".\n'
          'stdout:\n${_lines.join('\n')}\nstderr:\n$_stderr',
        );
      }
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        throw StateError(
          'Timed out waiting for "$needle".\n'
          'stdout:\n${_lines.join('\n')}\nstderr:\n$_stderr',
        );
      }
      final waiter = Completer<void>();
      _waiters.add(waiter);
      try {
        await waiter.future.timeout(remaining);
      } on TimeoutException {
        // The loop re-checks the deadline and reports diagnostics.
      } finally {
        _waiters.remove(waiter);
      }
    }
  }

  Future<int> waitForExit({
    Duration timeout = const Duration(seconds: 90),
  }) async {
    try {
      return await _exit.timeout(timeout);
    } on TimeoutException {
      await kill();
      throw StateError(
        'Worker did not exit in $timeout.\n'
        'stdout:\n${_lines.join('\n')}\nstderr:\n$_stderr',
      );
    }
  }

  /// Kills the process without letting Dart run `finally` blocks or catches.
  Future<void> kill() async {
    if (_exitCode != null) {
      return;
    }
    _process.kill(ProcessSignal.sigkill);
    try {
      await _exit.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // Nothing else can be done; the test's deadline reports the failure.
    }
  }

  void _wake() {
    final waiters = List<Completer<void>>.of(_waiters);
    _waiters.clear();
    for (final waiter in waiters) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
  }
}

/// Waits until [path] exists.
Future<void> waitForFile(
  String path, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!File(path).existsSync()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Timed out waiting for $path.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// [LocalDatabase] over one shared JSON file, writable by several processes.
///
/// Every operation re-reads and rewrites the file, so two processes see the same
/// state. It deliberately has no cross-process lock of its own: the tests pass a
/// [MutationLock] to prove that exclusion, not this test double, is what keeps
/// the queue consistent. Operations inside one process are serialized so a test
/// does not lose its own update.
final class JsonSharedDatabase implements LocalDatabase {
  JsonSharedDatabase(this.path);

  final String path;
  final SerialMutationLock _serial = SerialMutationLock();
  int _temporary = 0;

  Future<Map<String, Map<String, Map<String, Object?>>>> _load() async {
    final file = File(path);
    if (!file.existsSync()) {
      return <String, Map<String, Map<String, Object?>>>{};
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return <String, Map<String, Map<String, Object?>>>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw StateError('The shared database file is malformed.');
    }
    return <String, Map<String, Map<String, Object?>>>{
      for (final collection in decoded.entries)
        '${collection.key}': <String, Map<String, Object?>>{
          for (final record in (collection.value as Map).entries)
            '${record.key}': Map<String, Object?>.from(record.value as Map),
        },
    };
  }

  Future<void> _save(
    Map<String, Map<String, Map<String, Object?>>> data,
  ) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final text = jsonEncode(data);
    final temporary = File('$path.$pid.${_temporary++}.tmp');
    await temporary.writeAsString(text, flush: true);
    try {
      await temporary.rename(path);
    } on FileSystemException {
      // Windows refuses a rename over an open file; fall back to a direct
      // rewrite (the file lock, not this double, provides the exclusion).
      await file.writeAsString(text, flush: true);
      if (temporary.existsSync()) {
        await temporary.delete();
      }
    }
  }

  Map<String, Map<String, Object?>> _collection(
    Map<String, Map<String, Map<String, Object?>>> data,
    String collection,
  ) {
    return data[collection] ??= <String, Map<String, Object?>>{};
  }

  @override
  Future<void> put(
    String collection,
    String key,
    Map<String, Object?> data,
  ) {
    return _serial.runExclusive(() async {
      final contents = await _load();
      _collection(contents, collection)[key] = Map<String, Object?>.of(data);
      await _save(contents);
    });
  }

  @override
  Future<Map<String, Object?>?> get(String collection, String key) {
    return _serial.runExclusive(() async {
      final contents = await _load();
      final record = contents[collection]?[key];
      return record == null ? null : Map<String, Object?>.of(record);
    });
  }

  @override
  Future<List<LocalRecord>> query(
    String collection, {
    LocalQuery? query,
  }) {
    return _serial.runExclusive(() async {
      final contents = await _load();
      final records = <LocalRecord>[
        for (final entry
            in (contents[collection] ?? const <String, Map<String, Object?>>{})
                .entries)
          LocalRecord(
            key: entry.key,
            data: Map<String, Object?>.of(entry.value),
          ),
      ]..sort(
        (left, right) => '${left.data['createdAt']}'.compareTo(
          '${right.data['createdAt']}',
        ),
      );
      return records;
    });
  }

  @override
  Future<void> delete(String collection, String key) {
    return _serial.runExclusive(() async {
      final contents = await _load();
      contents[collection]?.remove(key);
      await _save(contents);
    });
  }

  @override
  Stream<List<LocalRecord>> watch(String collection, {LocalQuery? query}) =>
      const Stream<List<LocalRecord>>.empty();

  @override
  Future<void> close() async {}
}
