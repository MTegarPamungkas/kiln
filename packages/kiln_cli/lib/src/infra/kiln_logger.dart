import 'dart:io';

/// Small leveled logger that respects `--verbose` and `--quiet`.
final class KilnLogger {
  KilnLogger({
    this.verbose = false,
    this.quiet = false,
    void Function(String message)? out,
    void Function(String message)? err,
  }) : _out = out ?? stdout.writeln,
       _err = err ?? stderr.writeln;

  bool verbose;
  bool quiet;
  final void Function(String message) _out;
  final void Function(String message) _err;

  void configure({bool? verbose, bool? quiet}) {
    this.verbose = verbose ?? this.verbose;
    this.quiet = quiet ?? this.quiet;
  }

  void info(String message) {
    if (!quiet) {
      _out(message);
    }
  }

  /// Writes machine-readable output even when `--quiet` is active.
  void raw(String message) => _out(message);

  void success(String message) {
    if (!quiet) {
      _out('[ok] $message');
    }
  }

  void detail(String message) {
    if (verbose && !quiet) {
      _out('     $message');
    }
  }

  void warn(String message) {
    _err('[warn] $message');
  }

  void error(String message) {
    _err('[error] $message');
  }

  void blank() {
    if (!quiet) {
      _out('');
    }
  }
}
