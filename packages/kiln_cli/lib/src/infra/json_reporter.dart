import 'dart:convert';
import 'dart:io';

/// Writes stable JSON for `--json` output.
final class JsonReporter {
  const JsonReporter([this._out]);

  final void Function(String message)? _out;

  void write(Object? value) {
    final encoded = const JsonEncoder.withIndent('  ').convert(value);
    final sink = _out;
    if (sink != null) {
      sink(encoded);
    } else {
      stdout.writeln(encoded);
    }
  }
}
