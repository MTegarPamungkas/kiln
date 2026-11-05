// Private fields fed through named constructor parameters.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

/// One key press read from a terminal in raw mode.
enum RawKey { up, down, space, enter, cancel }

/// A terminal prepared for single-key reading.
abstract interface class RawModeSession {
  /// Blocks until one key is pressed.
  Future<RawKey> read();

  /// Restores the terminal modes that were active before [RawKeySource.enter].
  void restore();
}

/// Prepares a terminal for single-key reading.
///
/// [enter] returns null when raw input is unavailable — piped stdin, a
/// redirected handle, or a console without virtual terminal input — so callers
/// fall back to line-based prompts.
abstract interface class RawKeySource {
  RawModeSession? enter();
}

/// Reads keys from [stdin].
///
/// Arrow keys reach the process as ANSI escape sequences on POSIX terminals;
/// on Windows the console is switched to virtual terminal input so it reports
/// them the same way (Windows 10 or newer).
final class TerminalRawKeySource implements RawKeySource {
  const TerminalRawKeySource();

  @override
  RawModeSession? enter() {
    if (!stdin.hasTerminal) {
      return null;
    }
    final modes = _enableRawModes();
    if (modes == null) {
      return null;
    }
    final buffer = <int>[];
    Object? error;
    var notified = Completer<void>();
    final subscription = stdin.listen(
      (data) {
        buffer.addAll(data);
        if (!notified.isCompleted) {
          notified.complete();
        }
      },
      onError: (Object value) {
        error = value;
        if (!notified.isCompleted) {
          notified.complete();
        }
      },
    );
    return _TerminalSession(
      buffer: buffer,
      hasError: () => error != null,
      waitForData: () => notified.future,
      onNotify: () => notified = Completer<void>(),
      close: () {
        subscription.cancel();
        _restoreModes(modes);
      },
    );
  }
}

final class _TerminalSession implements RawModeSession {
  _TerminalSession({
    required List<int> buffer,
    required bool Function() hasError,
    required Future<void> Function() waitForData,
    required void Function() onNotify,
    required void Function() close,
  }) : _buffer = buffer,
       _hasError = hasError,
       _waitForData = waitForData,
       _onNotify = onNotify,
       _close = close;

  final List<int> _buffer;
  final bool Function() _hasError;
  final Future<void> Function() _waitForData;
  final void Function() _onNotify;
  final void Function() _close;

  @override
  Future<RawKey> read() async {
    while (true) {
      final byte = await _nextByte();
      switch (byte) {
        case 0x1b:
          // An escape sequence, or a lone escape used as cancel.
          final second = await _nextByteOrNull();
          if (second == null) {
            return RawKey.cancel;
          }
          final third = await _nextByteOrNull();
          if ((second == 0x5b || second == 0x4f) && third != null) {
            switch (third) {
              case 0x41:
                return RawKey.up;
              case 0x42:
                return RawKey.down;
            }
          }
          continue; // unknown sequence; ignore and read the next key
        case 0x20:
          return RawKey.space;
        case 0x0d:
        case 0x0a:
          return RawKey.enter;
        case 0x03:
          return RawKey.cancel;
      }
    }
  }

  @override
  void restore() {
    _close();
  }

  Future<int> _nextByte() async {
    while (true) {
      if (_buffer.isNotEmpty) {
        final byte = _buffer.removeAt(0);
        if (_buffer.isEmpty) {
          _onNotify();
        }
        return byte;
      }
      if (_hasError()) {
        throw const KilnException(
          'The terminal input stream failed.',
          code: 'prompt.invalid',
        );
      }
      await _waitForData();
      _onNotify();
    }
  }

  Future<int?> _nextByteOrNull() async {
    // A lone escape (cancel) vs an escape sequence (arrows) is decided by
    // whether more bytes arrive quickly.
    try {
      return await _nextByte().timeout(const Duration(milliseconds: 60));
    } on TimeoutException {
      return null;
    }
  }
}

({int input, int? output, bool windows})? _enableRawModes() {
  var rawModesApplied = false;
  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
    rawModesApplied = true;
    if (!Platform.isWindows) {
      return (input: 0, output: null, windows: false);
    }
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final getStdHandle = kernel32.lookupFunction<
        IntPtr Function(Uint32), int Function(int)>('GetStdHandle');
    final getMode = kernel32.lookupFunction<
        Int32 Function(IntPtr, Pointer<Uint32>),
        int Function(int, Pointer<Uint32>)>('GetConsoleMode');
    final setMode = kernel32.lookupFunction<
        Int32 Function(IntPtr, Uint32), int Function(int, int)>('SetConsoleMode');
    const inputHandle = 0xFFFFFFF6; // STD_INPUT_HANDLE
    const outputHandle = 0xFFFFFFF5; // STD_OUTPUT_HANDLE
    const enableVirtualTerminalInput = 0x0200;
    const enableVirtualTerminalProcessing = 0x0004;

    final input = getStdHandle(inputHandle);
    final inputMode = calloc<Uint32>();
    if (getMode(input, inputMode) == 0) {
      calloc.free(inputMode);
      return null;
    }
    final originalInput = inputMode.value;
    setMode(input, (originalInput | enableVirtualTerminalInput) & 0xFFFFFFFF);
    calloc.free(inputMode);

    int? originalOutput;
    final output = getStdHandle(outputHandle);
    final outputMode = calloc<Uint32>();
    if (getMode(output, outputMode) != 0) {
      originalOutput = outputMode.value;
      setMode(
        output,
        (originalOutput | enableVirtualTerminalProcessing) & 0xFFFFFFFF,
      );
    }
    calloc.free(outputMode);
    return (input: originalInput, output: originalOutput, windows: true);
  } on Object {
    // Test runners and non-console handles reject mode changes; fall back to
    // line-based prompts instead of failing.
    if (rawModesApplied) {
      try {
        stdin.lineMode = true;
        stdin.echoMode = true;
      } on Object {
        // Nothing further to restore.
      }
    }
    return null;
  }
}

void _restoreModes(
  ({int input, int? output, bool windows}) modes,
) {
  try {
    if (modes.windows) {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final getStdHandle = kernel32.lookupFunction<
          IntPtr Function(Uint32), int Function(int)>('GetStdHandle');
      final setMode = kernel32.lookupFunction<
          Int32 Function(IntPtr, Uint32), int Function(int, int)>('SetConsoleMode');
      setMode(getStdHandle(0xFFFFFFF6), modes.input);
      final output = modes.output;
      if (output != null) {
        setMode(getStdHandle(0xFFFFFFF5), output);
      }
    }
  } on Object {
    // The console is best-effort; never crash on restore.
  }
  stdin.lineMode = true;
  stdin.echoMode = true;
}
