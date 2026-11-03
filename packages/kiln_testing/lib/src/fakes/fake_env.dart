import 'package:kiln_core/kiln_core.dart';

/// [Env] backed by a map supplied by the test.
final class FakeEnv implements Env {
  FakeEnv([Map<String, String>? values])
    : _values = <String, String>{...?values};

  final Map<String, String> _values;

  void set(String key, String value) {
    _values[key] = value;
  }

  @override
  String? read(String key) => _values[key];

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  Map<String, String> get values => Map<String, String>.unmodifiable(_values);
}
