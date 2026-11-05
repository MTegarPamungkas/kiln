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
///
/// Keys are read with blocking `readByteSync` calls. The stream API is
/// deliberately avoided: on Windows, listening to `stdin` as a stream
/// invalidates the handle for later mode changes (`OS Error 6`), which would
/// break both this restore and every later prompt.
final class TerminalRawKeySource implements RawKeySource {
  const TerminalRawKeySource();

  @override
  RawModeSession? enter() {
    final modes = _enableRawModes();
    if (modes == null) {
      return null;
    }
    return _SyncSession(modes);
  }
}

final class _SyncSession implements RawModeSession {
  _SyncSession(this._modes);

  final ({int input, int? output, bool windows}) _modes;

  @override
  Future<RawKey> read() async {
    while (true) {
      final byte = _readByte();
      switch (byte) {
        case 0x1b:
          // An escape sequence (arrows) or a lone escape used as cancel. The
          // tail is read blocking; anything that is not a CSI sequence counts
          // as cancel, so Escape followed by any other key still cancels.
          final second = _readByte();
          if (second != 0x5b && second != 0x4f) {
            return RawKey.cancel;
          }
          switch (_readByte()) {
            case 0x41:
              return RawKey.up;
            case 0x42:
              return RawKey.down;
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
  void restore() => _restoreModes(_modes);

  static int _readByte() {
    final byte = stdin.readByteSync();
    if (byte < 0) {
      throw const KilnException(
        'The terminal input closed.',
        code: 'prompt.invalid',
      );
    }
    return byte;
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

void _restoreModes(({int input, int? output, bool windows}) modes) {
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
  try {
    stdin.lineMode = true;
    stdin.echoMode = true;
  } on Object {
    // dart:io can disagree about the handle after foreign mode changes; the
    // console mode itself was already restored above.
  }
}
