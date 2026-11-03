import 'dart:io';

import 'package:kiln_extension_sdk/kiln_extension_sdk.dart';

/// Terminal prompts that can be disabled with `--yes` or a non-TTY stdin.
final class Prompter {
  Prompter({
    this.assumeYes = false,
    this.interactive = true,
    String? Function(String prompt)? readLine,
    void Function(String message)? write,
  }) : _readLine = readLine ?? ((_) => stdin.readLineSync()),
       _write = write ?? stdout.write;

  final bool assumeYes;
  final bool interactive;
  final String? Function(String prompt) _readLine;
  final void Function(String message) _write;

  Prompter withAssumeYes(bool value) => Prompter(
    assumeYes: value,
    interactive: interactive,
    readLine: _readLine,
    write: _write,
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
        _write('Masukkan angka yang valid.\n');
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
