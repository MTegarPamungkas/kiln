import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kiln_core/kiln_core.dart';

/// Shared helpers for the multi-process storage tests.
///
/// A real second process is required: the checkpoint protocol must survive a
/// process death that no `catch` or `finally` can observe, and the advisory file
/// lock must be released by the operating system, not by Dart.

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

/// [Storage] over one JSON file, shared by the test and its worker processes.
///
/// This is a plain test double for durable key-value storage: every write
/// rewrites the whole file and flushes it, so a process death leaves exactly the
/// keys that were written before it. It is not a production adapter.
final class JsonFileStorage implements Storage {
  JsonFileStorage(this.path);

  final String path;

  Map<String, String> _readSync() {
    final file = File(path);
    if (!file.existsSync()) {
      return <String, String>{};
    }
    final raw = file.readAsStringSync();
    if (raw.trim().isEmpty) {
      return <String, String>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw StateError('The storage file $path is malformed.');
    }
    return <String, String>{
      for (final entry in decoded.entries) '${entry.key}': '${entry.value}',
    };
  }

  Future<void> _write(Map<String, String> values) async {
    await File(path).parent.create(recursive: true);
    await File(path).writeAsString(jsonEncode(values), flush: true);
  }

  @override
  Future<String?> read(String key) async => _readSync()[key];

  @override
  Future<void> write(String key, String value) async {
    final values = _readSync();
    values[key] = value;
    await _write(values);
  }

  @override
  Future<void> delete(String key) async {
    final values = _readSync();
    values.remove(key);
    await _write(values);
  }

  @override
  Future<bool> containsKey(String key) async => _readSync().containsKey(key);

  @override
  Future<Set<String>> keys() async => _readSync().keys.toSet();

  @override
  Future<void> clear() => _write(<String, String>{});
}
