import 'package:kiln_core/kiln_core.dart';

import 'env_schema.dart';

/// Reports every missing required key in one configuration Failure.
final class EnvValidator {
  const EnvValidator();

  /// Returns a configuration Failure when required keys are missing.
  Failure? check(Env env, EnvSchema schema) {
    final missing = <String>[
      for (final key in schema.keys)
        if (key.required && !env.containsKey(key.name)) key.name,
    ];
    if (missing.isEmpty) {
      return null;
    }
    return Failure(
      code: FailureCode.configurationMissing,
      message: 'Missing required environment values: ${missing.join(', ')}.',
      kind: FailureKind.configuration,
      details: <String, Object?>{'missing': missing},
    );
  }

  void validate(Env env, EnvSchema schema) {
    final failure = check(env, schema);
    if (failure != null) {
      throw failure;
    }
  }
}
