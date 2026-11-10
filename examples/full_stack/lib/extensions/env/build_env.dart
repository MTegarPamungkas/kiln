import 'package:kiln_core/kiln_core.dart';

import 'build_env_values.dart';
import 'env_schema.dart';

/// [Env] backed by compiled `--dart-define` values.
final class BuildEnv implements Env {
  BuildEnv({EnvSchema? schema, Map<String, String>? values})
    : schema = schema ?? EnvSchema.defaults,
      _values = values ?? BuildEnvValues.values;

  final EnvSchema schema;
  final Map<String, String> _values;

  @override
  String? read(String key) {
    if (!schema.contains(key)) {
      return null;
    }
    return _values[key];
  }

  @override
  bool containsKey(String key) {
    final value = read(key);
    return value != null && value.isNotEmpty;
  }

  @override
  Map<String, String> get values {
    return <String, String>{
      for (final key in schema.keys)
        if (_values[key.name]?.isNotEmpty ?? false)
          key.name: _values[key.name]!,
    };
  }
}
