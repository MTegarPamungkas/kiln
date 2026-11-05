import 'package:kiln_core/kiln_core.dart';

import 'env_schema.dart';

/// Reports every missing required key in one configuration Failure.
final class EnvValidator {
  const EnvValidator();

  void validate(Env env, EnvSchema schema) {
    final missing = <String>[
      for (final key in schema.keys)
        if (key.required && !env.containsKey(key.name)) key.name,
    ];
    if (missing.isEmpty) {
      return;
    }
    throw Failure(
      code: FailureCode.configurationMissing,
      message:
          'Nilai environment wajib belum diisi: ${missing.join(', ')}.',
      kind: FailureKind.configuration,
      details: <String, Object?>{'missing': missing},
    );
  }
}
