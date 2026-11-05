import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

import 'raw_keys.dart';

/// Terminal prompts that can be disabled with `--yes` or a non-TTY stdin.
final class Prompter {
  Prompter({
    this.assumeYes = false,
    this.interactive = true,
    String? Function(String prompt)? readLine,
    void Function(String message)? write,
    RawKeySource? rawKeys,
  }) : _readLine = readLine ?? ((_) => stdin.readLineSync()),
       _write = write ?? stdout.write,
       _rawKeys = rawKeys ?? const TerminalRawKeySource();

  final bool assumeYes;
  final bool interactive;
  final String? Function(String prompt) _readLine;
  final void Function(String message) _write;
  final RawKeySource _rawKeys;

  Prompter withAssumeYes(bool value) => Prompter(
    assumeYes: value,
    interactive: interactive,
    readLine: _readLine,
    write: _write,
    rawKeys: _rawKeys,
  );

  bool confirm(String question, {bool defaultValue = false}) {
    if (assumeYes) {
      return true;
    }
    if (!interactive) {
      return defaultValue;
    }
    final suffix = defaultValue ? '[Y/n]' : '[y/N]';
    _write('$question $suffix ');
    final answer = _readLine(question)?.trim().toLowerCase();
    if (answer == null || answer.isEmpty) {
      return defaultValue;
    }
    return answer == 'y' || answer == 'yes' || answer == 'ya';
  }

  String? text(String question, {String? defaultValue, bool secret = false}) {
    if (assumeYes && defaultValue != null) {
      return defaultValue;
    }
    if (!interactive) {
      return defaultValue;
    }
    final suffix = defaultValue == null ? '' : ' [$defaultValue]';
    _write('$question$suffix ');
    if (!secret) {
      final answer = _readLine(question)?.trim();
      return answer == null || answer.isEmpty ? defaultValue : answer;
    }
    final previousEchoMode = stdin.echoMode;
    try {
      stdin.echoMode = false;
      final answer = stdin.readLineSync()?.trim();
      return answer == null || answer.isEmpty ? defaultValue : answer;
    } finally {
      stdin.echoMode = previousEchoMode;
    }
  }

  String select(String question, List<String> options, {String? defaultValue}) {
    if (options.isEmpty) {
      throw const KilnException(
        'No options available',
        code: 'prompt.no_options',
      );
    }
    if (assumeYes && defaultValue != null) {
      return defaultValue;
    }
    if (!interactive) {
      if (defaultValue != null) {
        return defaultValue;
      }
      throw KilnException(
        '$question needs an answer (${options.join(', ')})',
        code: 'prompt.required',
        suggestion: 'Pass --yes with a default or run interactively',
      );
    }

    _write('$question\n');
    for (var index = 0; index < options.length; index++) {
      final marker = options[index] == defaultValue ? ' (default)' : '';
      _write('  ${index + 1}. ${options[index]}$marker\n');
    }
    _write('> ');
    final answer = _readLine(question)?.trim();
    if (answer == null || answer.isEmpty) {
      if (defaultValue != null) {
        return defaultValue;
      }
      return options.first;
    }
    final index = int.tryParse(answer);
    if (index != null && index >= 1 && index <= options.length) {
      return options[index - 1];
    }
    if (options.contains(answer)) {
      return answer;
    }
    throw KilnException(
      '"$answer" is not one of ${options.join(', ')}',
      code: 'prompt.invalid',
    );
  }

  /// Multi-select with a checkbox display. [defaults] start checked. In a raw
  /// terminal the arrows move, Space toggles, and Enter confirms; otherwise
  /// typed numbers (separated by spaces or commas) toggle entries and an
  /// empty line keeps the selection as shown.
  Future<List<String>> selectMany(
    String question,
    List<String> options, {
    Set<String> defaults = const <String>{},
  }) async {
    if (options.isEmpty) {
      throw const KilnException(
        'No options available',
        code: 'prompt.no_options',
      );
    }
    if (assumeYes || !interactive) {
      return <String>[
        for (final option in options)
          if (defaults.contains(option)) option,
      ];
    }

    final session = _rawKeys.enter();
    if (session == null) {
      return _selectManyByNumbers(question, options, defaults);
    }
    return _selectManyRaw(question, options, defaults, session);
  }

  /// Checkbox loop reading single keys: arrows move the pointer, Space
  /// toggles the pointed entry, Enter confirms, and Escape or Ctrl+C cancels.
  Future<List<String>> _selectManyRaw(
    String question,
    List<String> options,
    Set<String> defaults,
    RawModeSession session,
  ) async {
    final selected = <String>{...defaults};
    var cursor = 0;
    _write('$question\n');
    _write('↑/↓ move, Space toggles, Enter confirms, Esc cancels\n');
    try {
      _write('\x1b[?25l'); // hide the cursor while the frame redraws
      void draw({required bool moveBack}) {
        final frame = StringBuffer();
        if (moveBack) {
          frame.write('\x1b[${options.length}A');
        }
        for (var index = 0; index < options.length; index++) {
          final checked = selected.contains(options[index]) ? 'x' : ' ';
          final pointer = index == cursor ? '>' : ' ';
          frame
            ..write('\x1b[2K')
            ..write('  $pointer ${index + 1}. [$checked] ${options[index]}\n');
        }
        _write(frame.toString());
      }

      draw(moveBack: false);
      while (true) {
        final key = await session.read();
        switch (key) {
          case RawKey.up:
            if (cursor > 0) {
              cursor--;
            }
            draw(moveBack: true);
          case RawKey.down:
            if (cursor < options.length - 1) {
              cursor++;
            }
            draw(moveBack: true);
          case RawKey.space:
            if (!selected.remove(options[cursor])) {
              selected.add(options[cursor]);
            }
            draw(moveBack: true);
          case RawKey.enter:
            return <String>[
              for (final option in options)
                if (selected.contains(option)) option,
            ];
          case RawKey.cancel:
            throw const KilnException(
              'Cancelled.',
              code: 'prompt.cancelled',
            );
        }
      }
    } finally {
      _write('\x1b[?25h'); // show the cursor again
      session.restore();
    }
  }

  /// Fallback for terminals without raw input: type numbers to toggle.
  List<String> _selectManyByNumbers(
    String question,
    List<String> options,
    Set<String> defaults,
  ) {
    final selected = <String>{...defaults};
    _write('$question\n');
    for (var index = 0; index < options.length; index++) {
      final marker = selected.contains(options[index]) ? 'x' : ' ';
      _write('  ${index + 1}. [$marker] ${options[index]}\n');
    }
    _write('> (numbers toggle, Enter keeps the selection) ');
    final answer = _readLine(question)?.trim();
    if (answer == null || answer.isEmpty) {
      return <String>[
        for (final option in options)
          if (selected.contains(option)) option,
      ];
    }
    for (final token in answer.split(RegExp(r'[,\s]+'))) {
      if (token.isEmpty) {
        continue;
      }
      final index = int.tryParse(token);
      if (index == null || index < 1 || index > options.length) {
        throw KilnException(
          '"$token" is not a checkbox number (1-${options.length})',
          code: 'prompt.invalid',
        );
      }
      final option = options[index - 1];
      if (!selected.remove(option)) {
        selected.add(option);
      }
    }
    return <String>[
      for (final option in options)
        if (selected.contains(option)) option,
    ];
  }

  int? integer(String question, {int? defaultValue, int? min, int? max}) {
    if (assumeYes) {
      return defaultValue;
    }
    if (!interactive) {
      return defaultValue;
    }
    while (true) {
      final answer = text(question, defaultValue: defaultValue?.toString());
      final value = int.tryParse(answer ?? '');
      if (value == null) {
        _write('Enter a valid number.\n');
        continue;
      }
      if (min != null && value < min) {
        _write('Minimum value $min.\n');
        continue;
      }
      if (max != null && value > max) {
        _write('Maximum value $max.\n');
        continue;
      }
      return value;
    }
  }
}
