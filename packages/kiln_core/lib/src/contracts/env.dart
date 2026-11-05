/// Build-time configuration read from `--dart-define` values.
abstract interface class Env {
  String? read(String key);

  bool containsKey(String key);

  Map<String, String> get values;
}
