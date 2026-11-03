import 'package:kiln_core/kiln_core.dart';

import 'env_schema.dart';

/// Builds a log-safe summary of the environment.
final class EnvDescribe {
  const EnvDescribe({this.replacement = '[redacted]'});

  final String replacement;

  Map<String, String> summarize(Env env, EnvSchema schema) {
    return <String, String>{
      for (final key in schema.keys)
        key.name: key.secret
            ? (env.containsKey(key.name) ? replacement : '')
            : (env.read(key.name) ?? ''),
    };
  }
}
